# frozen_string_literal: true

# This job creates a Webex conference & link for a non virtual hearing

class Hearings::CreateNonVirtualConferenceJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :high_priority
  application_attr :hearing_schedule
  attr_reader :hearing

  # Retry if Webex returns an invalid response.
  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    job.log_error(exception)
  end

  def perform(hearing:)
    ensure_current_user_is_set
    WebexConferenceLink.find_or_create_by!(
      hearing_id: hearing.id,
      hearing_type: hearing.readable_request_type,
      hearing: hearing,
      created_by: hearing.created_by
    )
  end

  def log_error(error)
    Rails.logger.error("Retrying #{self.class.name} because failed with error: #{error}")
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    Raven.capture_exception(error, extra: extra)
  end
end
