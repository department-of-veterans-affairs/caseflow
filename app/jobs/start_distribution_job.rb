# frozen_string_literal: true

class StartDistributionJob < ApplicationJob
  queue_as :high_priority
  application_attr :queue

  def perform(distribution, user = nil)
    RequestStore.store[:current_user] = user if user
    distribution.distribute!
  rescue StandardError => e
    Rails.logger.info "StartDistributionJob failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
  end

  # :nocov:
  def max_attempts
    1
  end
  # :nocov:
end
