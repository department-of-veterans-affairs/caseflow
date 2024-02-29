# frozen_string_literal: true

# This job creates a Webex conference & link for a non virtual hearing

class Hearings::CreateNonVirtualConferenceJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :high_priority
  application_attr :hearing_schedule
  attr_reader :hearing

  class IncompleteError < StandardError; end
  class HearingRequestCancelledError < StandardError; end
  class HearingNotCreatedError < StandardError; end
  class HearingIsPexipError < StandardError; end
  class HearingAlreadyHeldError < StandardError; end
  class HearingPostponedError < StandardError; end
  # class LinkGenerationFailed < StandardError; end

  # discard_on(LinkGenerationFailed) do |job, _exception|
  #   Rails.logger.warn(
  #     "Discarding #{job.class.name} (#{job.job_id}) because links could not be generated"
  #   )
  # end

  discard_on(HearingRequestCancelledError) do |job, _exception|
    Rails.logger.warn(
      "Discarding #{job.class.name} (#{job.job_id}) because virtual hearing request was cancelled"
    )
  end

  retry_on(IncompleteError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  retry_on(HearingNotCreatedError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  # Retry if Webex returns an invalid response.
  retry_on(Caseflow::Error::WebexApiError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    kwargs = job.arguments.first
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: kwargs[:hearing_id],
    }

    Raven.capture_exception(exception, extra: extra)
  end

  def perform(hearing:)
    ensure_current_user_is_set
    ensure_hearing(hearing)

    WebexConferenceLink.find_or_create_by!(
      hearing_id: hearing.id,
      hearing_type: hearing.readable_request_type,
      hearing: hearing,
      created_by: hearing.created_by
    )
  end

  private

  def ensure_hearing(hearing)
    fail HearingNotCreatedError if hearing.nil?
    fail HearingRequestCancelledError if hearing.cancelled?
    fail HearingPostponedError if hearing.disposition == "postponed"
    fail HearingIsPexipError if hearing.determine_service_name == "webex"
    fail HearingAlreadyHeldError if hearing.disposition == "held"
  end
end
