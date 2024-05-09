# frozen_string_literal: true

class StartDistributionJob < ApplicationJob
  include RunAsyncable

  queue_with_priority :high_priority
  application_attr :queue

  def perform(distribution, user = nil)
    RequestStore.store[:current_user] = user if user
    distribution.distribute!
    perform_later_or_now(UpdateAppealAffinityDatesJob, distribution.id)
  rescue StandardError => error
    handle_error(error)
    # do not re-raise, since we only want to run once.
  end

  private

  def handle_error(error)
    Rails.logger.info "StartDistributionJob failed: #{error.message}"
    Rails.logger.info error.backtrace.join("\n")
    capture_exception(error: error)
  end
end
