require 'bertrpc'
service = BERTRPC::Service.new('localhost', 9777)

loop do
  begin
    puts ">> add(10, 32)"
    res = service.call.example.send(:add, 10, 32)
    puts "=> #{res.inspect}"
  rescue => boom
    puts "ERROR: #{boom.class} #{boom}"
  end
  sleep 1
end
