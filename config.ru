# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "rack"

# rubocop:disable all
module PumaThreadLogger
  def initialize *args
    Thread.new do
      loop do
        sleep 30

        thread_count = 0
        backlog = 0
        waiting = 0

        # Safely access the thread information.
        # Note that this might slow down performance.
        @mutex.synchronize {
          thread_count = @workers.size
          backlog = @todo.size
          waiting = @waiting
        }

        emit_metrics_point("idle", waiting)
        emit_metrics_point("active", thread_count - waiting)

        # For some reason, even a single Puma server (not clustered) has two booted ThreadPools.
        # One of them is empty, and the other is actually doing work.
        # The check above ignores the empty one.
        if thread_count > 0
          # It might be cool if we knew the Puma worker index for this worker,
          # but that didn't look easy to me.
          # I'm not 100% confident of the right way to measure this,
          # so I added a few.
          msg = "Puma stats -- Process pid: #{Process.pid} "\
           "Total threads: #{thread_count} "\
           "Backlog of actions: #{backlog} "\
           "Waiting threads: #{waiting} "\
           "Active threads: #{thread_count - waiting} "\
           "Live threads: #{@workers.select{|x| x.alive?}.size}/#{@workers.size} alive"
          Rails.logger.info(msg)
        end

      end
    end
    super *args
  end

  def emit_metrics_point(type, count)
    MetricsService.emit_gauge(
      metric_group: "puma",
      metric_name: "#{type}_threads",
      metric_value: count,
      app_name: "caseflow"
    )
  end
end

if ENV["THREAD_LOGGING"] == "enabled"
  module Puma
    class ThreadPool
      prepend PumaThreadLogger
    end
  end
end
# rubocop:enable all

run Rails.application
Rails.application.load_server
