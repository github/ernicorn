require 'bert'
require 'logger'
require 'ernicorn/version'

module Ernicorn
  class << self
    attr_accessor :mods, :current_mod, :log
    attr_accessor :count, :virgin_procline, :serializer
  end

  self.count = 0
  self.virgin_procline = $0
  self.mods = {}
  self.current_mod = nil
  self.log = Logger.new(STDOUT)
  self.log.level = Logger::FATAL
  self.serializer = BERT

  # Record a module.
  #   +name+ is the module Symbol
  #   +block+ is the Block containing function definitions
  #
  # Returns nothing
  def self.mod(name, block)
    m = Mod.new(name)
    self.current_mod = m
    self.mods[name] = m
    block.call
  end

  # Record a function.
  #   +name+ is the function Symbol
  #   +block+ is the Block to associate
  #
  # Returns nothing
  def self.fun(name, block)
    self.current_mod.fun(name, block)
  end

  # Expose all public methods in a Ruby module:
  #   +name+ is the ernie module Symbol
  #   +mixin+ is the ruby module whose public methods are exposed
  #
  # Returns nothing
  def self.expose(name, mixin)
    context = Object.new
    context.extend mixin
    mod(name, lambda {
      mixin.public_instance_methods.each do |meth|
        fun(meth.to_sym, context.method(meth))
      end
    })
    if defined? mixin.dispatched
      self.current_mod.logger = mixin.method(:dispatched)
    end
    context
  end

  # Set the logfile to given path.
  #   +file+ is the String path to the logfile
  #
  # Returns nothing
  def self.logfile(file)
    self.log = Logger.new(file)
  end

  # Set the log level.
  #   +level+ is the Logger level (Logger::WARN, etc)
  #
  # Returns nothing
  def self.loglevel(level)
    self.log.level = level
  end

  # Dispatch the request to the proper mod:fun.
  #   +mod+ is the module Symbol
  #   +fun+ is the function Symbol
  #   +args+ is the Array of arguments
  #
  # Returns the Ruby object response
  def self.dispatch(mod, fun, args)
    self.mods[mod] || raise(ServerError.new("No such module '#{mod}'"))
    self.mods[mod].funs[fun] || raise(ServerError.new("No such function '#{mod}:#{fun}'"))

    start = Time.now
    ret = self.mods[mod].funs[fun].call(*args)

    begin
      self.mods[mod].logger and
      self.mods[mod].logger.call(Time.now-start, [fun, *args], ret)
    rescue Object => e
      self.log.fatal(e)
    end

    ret
  end

  # Read the length header from the wire.
  #   +input+ is the IO from which to read
  #
  # Returns the size Integer if one was read
  # Returns nil otherwise
  def self.read_4(input)
    raw = input.read(4)
    return nil unless raw
    raw.unpack('N').first
  end

  # Read a BERP from the wire and decode it to a Ruby object.
  #   +input+ is the IO from which to read
  #
  # Returns a Ruby object if one could be read
  # Returns nil otherwise
  def self.read_berp(input)
    packet_size = self.read_4(input)
    return nil unless packet_size
    bert = input.read(packet_size)
    serializer.decode(bert)
  end

  # Write the given Ruby object to the wire as a BERP.
  #   +output+ is the IO on which to write
  #   +ruby+ is the Ruby object to encode
  #
  # Returns nothing
  def self.write_berp(output, ruby)
    data = serializer.encode(ruby)
    output.write([data.bytesize].pack("N"))
    output.write(data)
  end

  # Start the processing loop.
  #
  # Loops forever
  def self.start
    self.procline('starting')
    self.log.info("(#{Process.pid}) Starting") if self.log.level <= Logger::INFO
    self.log.debug(self.mods.inspect) if self.log.level <= Logger::DEBUG

    input = IO.new(3)
    output = IO.new(4)
    input.sync = true
    output.sync = true

    loop do
      process(input, output)
    end
  end

  # Processes a single BertRPC command.
  #
  #   input  - The IO to #read command BERP from.
  #   output - The IO to #write reply BERP to.
  #
  # Returns a [iruby, oruby] tuple of incoming and outgoing BERPs processed.
  def self.process(input, output)
    self.procline('waiting')
    iruby = self.read_berp(input)
    return nil if iruby.nil?

    self.count += 1

    if iruby.size == 4 && iruby[0] == :call
      mod, fun, args = iruby[1..3]
      self.procline("#{mod}:#{fun}(#{args})")
      self.log.info("-> " + iruby.inspect) if self.log.level <= Logger::INFO
      begin
        res = self.dispatch(mod, fun, args)
        oruby = t[:reply, res]
        self.log.debug("<- " + oruby.inspect) if self.log.level <= Logger::DEBUG
        write_berp(output, oruby)
      rescue ServerError => e
        oruby = t[:error, t[:server, 0, e.class.to_s, e.message, e.backtrace]]
        self.log.error("<- " + oruby.inspect) if self.log.level <= Logger::ERROR
        self.log.error(e.backtrace.join("\n")) if self.log.level <= Logger::ERROR
        write_berp(output, oruby)
      rescue Object => e
        oruby = t[:error, t[:user, 0, e.class.to_s, e.message, e.backtrace]]
        self.log.error("<- " + oruby.inspect) if self.log.level <= Logger::ERROR
        self.log.error(e.backtrace.join("\n")) if self.log.level <= Logger::ERROR
        write_berp(output, oruby)
      end
    elsif iruby.size == 4 && iruby[0] == :cast
      mod, fun, args = iruby[1..3]
      self.procline("#{mod}:#{fun}(#{args})")
      self.log.info("-> " + [:cast, mod, fun, args].inspect) if self.log.level <= Logger::INFO
      oruby = t[:noreply]
      write_berp(output, oruby)

      begin
        self.dispatch(mod, fun, args)
      rescue Object => e
        # ignore
      end
    else
      self.procline("invalid request")
      self.log.error("-> " + iruby.inspect) if self.log.level <= Logger::ERROR
      oruby = t[:error, t[:server, 0, "Invalid request: #{iruby.inspect}"]]
      self.log.error("<- " + oruby.inspect) if self.log.level <= Logger::ERROR
      write_berp(output, oruby)
    end

    self.procline('waiting')
    [iruby, oruby]
  end

  def self.procline(msg)
    $0 = "ernicorn handler #{VERSION} (ruby) - #{self.virgin_procline} - [#{self.count}] #{msg}"[0..159]
  end

  def self.version
    VERSION
  end

  class ServerError < StandardError; end

  class Ernicorn::Mod
    attr_accessor :name, :funs, :logger

    def initialize(name)
      self.name = name
      self.funs = {}
      self.logger = nil
    end

    def fun(name, block)
      raise TypeError, "block required" if block.nil?
      self.funs[name] = block
    end
  end
end
# Root level calls

def logfile(name)
  Ernicorn.logfile(name)
end

def loglevel(level)
  Ernicorn.loglevel(level)
end
