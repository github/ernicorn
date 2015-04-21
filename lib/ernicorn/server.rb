require 'unicorn'

module Ernicorn
  Stats = Raindrops::Struct.new(:connections_total,
                                :connections_completed,
                                :workers_idle).new

  class Server < Unicorn::HttpServer

    # Private HttpServer methods we're overriding to
    # implement BertRPC instead of HTTP.

    def initialize(app, options={})
      super app, options
    end

    def build_app!
    end

    def worker_loop(worker)
      Stats.incr_workers_idle

      if worker.nr == (self.worker_processes - 1)
        old_pid = "#{self.pid}.oldbin"
        if File.exists?(old_pid) && self.pid != old_pid
          begin
            Process.kill("QUIT", File.read(old_pid).to_i)
          rescue Errno::ENOENT, Errno::ESRCH
            # someone else did our job for us
          end
        end
      end

      super
    ensure
      Stats.decr_workers_idle
    end

    def process_client(client)
      Ernicorn.respond_to?(:around_filter) ?
        Ernicorn.around_filter { process_ernicorn_client(client) } :
        process_ernicorn_client(client)
    end

    def process_ernicorn_client(client)
      Stats.decr_workers_idle
      Stats.incr_connections_total

      @client = client
      # bail out if client only sent EOF
      return if @client.kgio_trypeek(1).nil?

      iruby, oruby = Ernicorn.process(self, self)
    rescue EOFError
      logger.error("EOF from #{@client.kgio_addr rescue nil}")
    rescue Object => e
      logger.error(e)

      begin
        error = t[:error, t[:server, 0, e.class.to_s, e.message, e.backtrace]]
        Ernicorn.write_berp(self, error)
      rescue Object => ex
        logger.error(ex)
      end
    ensure
      @client.close rescue nil
      @client = nil

      Stats.incr_connections_completed
      Stats.incr_workers_idle
    end

    # We pass ourselves as both input and output to Ernicorn.process, which
    # calls the following blocking read/write methods.

    def read(len)
      data = ''
      while data.bytesize < len
        data << @client.kgio_read!(len - data.bytesize)
      end
      data
    end

    def write(data)
      @client.kgio_write(data)
    end

    def stop(graceful = true)
      self.pid = "#{self.pid}.#{$$}" if pid =~ /\.oldbin\z/
      super
    end
  end
end
