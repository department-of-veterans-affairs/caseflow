# frozen_string_literal: true

class Hearings::HearingEmailStatusJob < ApplicationJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    ensure_current_user_is_set

    HearingRepository.maybe_needs_email_sent_status_checked.each do |sent_hearing_email_event|
      begin
        check_and_handle_reported_status(sent_hearing_email_event)
      rescue StandardError => error # rescue any error and allow job to continue
        capture_exception(error: error)
      end
    end
  end

  private

  def check_and_handle_reported_status(sent_hearing_email_event)
    reported_status =
      ExternalApi::GovDeliveryService.get_sent_status_from_event(email_event: sent_hearing_email_event)

    sent_hearing_email_event.handle_reported_status(reported_status) unless reported_status.nil?
  end
end
