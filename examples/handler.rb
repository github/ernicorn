# An example BERTRPC server module. To start the RPC server use:
#
#    $ bin/ernicorn -p 9675 examples/handler.rb
#
# Then connect and issue commands as follows:
#
#    $ script/console
#    >> require 'bertrpc'
#    >> service = BERTRPC::Service.new('localhost', 9675)
#    => #<BERTRPC::Service:0x1037e9678 @port=9765, @timeout=nil, @host="localhost">
#    >> service.call.example.send(:add, 1, 2)
#    => 3
#    >> service.call.example.send(:fib, 10)
#    => 89

module Example
  # Add two numbers together
  def add(a, b)
    a + b
  end

  def fib(n)
    if n == 0 || n == 1
      1
    else
      fib(n - 1) + fib(n - 2)
    end
  end

  def shadow(x)
    "ruby"
  end

  # Return the given number of bytes
  def bytes(n)
    'x' * n
  end

  # Sleep for +sec+ and then return :ok
  def slow(sec)
    sleep(sec)
    :ok
  end

  # Throw an error
  def error
    raise "abandon hope!"
  end
end
