Ernicorn
========

A BERT-RPC server based on [Ernie](https://github.com/mojombo/ernie)'s Ruby
interface but that uses [Unicorn](http://unicorn.bogomips.org/) for worker
process management.

Ernicorn supports BERT-RPC `call` and `cast` requests. See the full BERT-RPC
specification at [bert-rpc.org](http://bert-rpc.org) for more information.

Like Ernie before it, Ernicorn was developed at GitHub and is currently in
production use serving millions of RPC requests every day.

Installation
------------

    $ gem install ernicorn

Starting The Server
-------------------

Use the `ernicorn` command to start a new RPC server:

    $ ernicorn --help
    Usage: ernicorn [options] [config file]
    Start a Ruby BERT-RPC Server with the given options and config file.

    Options
      -h, --host=<host>          Server address to listen on; default: 0.0.0.0
      -p, --port=<portno>        Server port to listen on; default: 8149
      -l, --listen=<host>:<port> Listen addresses. Can be specified multiple times
          --log-level=0-4        Set the log level
      -d, --detached             Run as a daemon
      -P, --pidfile=<file>       Location to write pid file

The ernicorn server attempts to load the config file given or
`config/ernicorn.rb` when no config file is specified. See the example config
file [examples/config.rb][c] to get started. All [Unicorn config options][r] are
supported.

The config file should require any libraries needed for the server and register
server modules with `Ernicorn.expose(:modulename, TheModule)`. See the
[examples/handler.rb][h] file for a simple example handler.

[h]: https://github.com/github/ernicorn/blob/master/examples/handler.rb
[c]: https://github.com/github/ernicorn/blob/master/examples/config.rb
[r]: http://unicorn.bogomips.org/Unicorn/Configurator.html

Control Commands
----------------

The `ernicorn-ctrl` command can be used to send various control and
informational commands to the running server process:

    $ ernicorn-ctrl --help
    Usage: ernicorn-ctrl [-p <port>] <command>
    Issue a control command to an ernicorn server. The port option is used to
    specify a non-default control port.

    Commands:
      reload-handlers         Gracefully reload all handler processes.
      stats                   Dump handler stats for the server.
      halt                    Shut down.

Ernicorn servers also support most Unicorn signals for managing worker processes
and whatnot. See the [SIGNALS](http://unicorn.bogomips.org/SIGNALS.html) file
for more info.

Development
-----------

The `script/bootstrap` command is provided to setup a local gem environment for
development.

    $ script/bootstrap

It installs all gems under `vendor/gems` and creates binstubs under a `bin`
directory. This is the best way to get setup for running tests and experimenting
in a sandbox.
