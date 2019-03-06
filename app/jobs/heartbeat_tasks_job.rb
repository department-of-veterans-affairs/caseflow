# frozen_string_literal: true

# This is a noop debug job used for development and testing of
# background jobs
class HeartbeatTasksJob < ApplicationJob
  queue_as :low_priority

  def perform
    Rails.logger.info "This is a heartbeat ping"
  end
end
