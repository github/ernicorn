# Ernicorn configuration
#
# Ernicorn config files typically live at config/ernicorn.rb and support all
# Unicorn config options:
#
#    http://unicorn.bogomips.org/Unicorn/Configurator.html
#
# Example unicorn config files:
#
#   http://unicorn.bogomips.org/examples/unicorn.conf.rb
#   http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
warn "in unicorn config file: #{__FILE__}"

# server options
listen 9777
worker_processes 2
working_directory File.dirname(__FILE__)

# ernicorn configuration
Ernicorn.loglevel 1

# enable COW where possible
GC.respond_to?(:copy_on_write_friendly=) &&
  GC.copy_on_write_friendly = true

# load server code and expose modules
require File.expand_path('../handler', __FILE__)
Ernicorn.expose(:example, Example)

# hook into new child immediately after forking
after_fork  do |server, worker|
end

# hook into master immediately before forking a worker
before_fork do |server, worker|
end
