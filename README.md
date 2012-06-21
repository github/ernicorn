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

Use the ernicorn command to start a new RPC server:

    [rtomayko@iron:ernicorn]$ ernicorn --help
    Ernicorn is an Ruby BERT-RPC Server based on Unicorn.

    Basic Command Line Usage:
      ernicorn [options] <handler>

        -c, --config CONFIG              Unicorn style config file
        -p, --port PORT                  Port
        -l, --log-level LOGLEVEL         Log level (0-4)
        -d, --detached                   Run as a daemon
        -P, --pidfile PIDFILE            Location to write pid file.

The handler must be given and should be a normal Ruby file that sets up the
environment and calls `Ernicorn.expose` for any server modules. See the
[examples/handler.rb][h] file for more info.

[h]: https://github.com/github/ernicorn/blob/master/examples/handler.rb

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
