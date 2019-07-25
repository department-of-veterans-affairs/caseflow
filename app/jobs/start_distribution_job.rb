# frozen_string_literal: true

class StartDistributionJob < ApplicationJob
  queue_as :high_priority
  application_attr :queue

  def perform(distribution, user = nil)
    RequestStore.store[:current_user] = user if user
    distribution.distribute!
  rescue StandardError => error
    handle_error(error)
    # do not re-raise, since we only want to run once.
  end

  private

  def handle_error(error)
    Rails.logger.info "StartDistributionJob failed: #{error.message}"
    Rails.logger.info error.backtrace.join("\n")
    Raven.capture_exception(error)
  end
end
