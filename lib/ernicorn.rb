require 'ernie'
require 'unicorn'

module Ernicorn
  Stats = Raindrops::Struct.new(:connections_total,
                                :connections_completed,
                                :workers_idle).new

  class Server < Unicorn::HttpServer

    # Private HttpServer methods we're overriding to
    # implement BertRPC instead of HTTP.

    def initialize(handler, options={})
      @handler = handler
      super nil, options
    end

    def build_app!
      logger.info "Loading ernie handler: #{@handler}"
      require @handler
    end

    def worker_loop(worker)
      Stats.incr_workers_idle
      super
    ensure
      Stats.decr_workers_idle
    end

    def process_client(client)
      Stats.decr_workers_idle
      Stats.incr_connections_total

      @client = client
      iruby, oruby = Ernie.process(self, self)
    ensure
      @client.close
      @client = nil

      Stats.incr_connections_completed
      Stats.incr_workers_idle
    end

    # We pass ourselves as both input and output to Ernie.process, which
    # calls the following blocking read/write methods.

    def read(len)
      data = ''
      while @client.kgio_read!(len - data.bytesize, data) == :wait_readable
        IO.select([@client])
      end
      data
    end

    def write(data)
      @client.kgio_write(data)
    end
  end

  module AdminRPC
    def stats
      queued = active = 0

      Raindrops::Linux.tcp_listener_stats(Unicorn.listener_names).each do |addr,stats|
        queued += stats.queued
        active += stats.active
      end if defined?(Raindrops::Linux)

      return <<STATS
connections.total=#{Stats.connections_total}
connections.completed=#{Stats.connections_completed}
workers.idle=#{Stats.workers_idle}
workers.busy=#{active}
queue.high=#{queued}
queue.low=0
STATS
    end

    def reload_handlers
      Process.kill 'HUP', master_pid
      "Sent HUP to #{master_pid}"
    end

    def halt
      Process.kill 'QUIT', master_pid
      "Sent QUIT to #{master_pid}"
    end

    def master_pid
      $ernicorn.master_pid
    end
  end
end

Ernie.expose(:__admin__, Ernicorn::AdminRPC)
