require 'unicorn'

module Ernicorn
  module AdminRPC
    def stats
      queued = active = 0

      Raindrops::Linux.tcp_listener_stats(Unicorn.listener_names).each do |addr,stats|
        queued += stats.queued
        active += stats.active
      end if defined?(Raindrops::Linux.tcp_listener_stats)

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
      Process.kill 'USR2', master_pid
      "Sent USR2 to #{master_pid}"
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

Ernicorn.expose(:__admin__, Ernicorn::AdminRPC)
