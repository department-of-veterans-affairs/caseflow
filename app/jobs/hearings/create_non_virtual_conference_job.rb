# frozen_string_literal: true

# This job creates a Webex conference & link for a non virtual hearing

class Hearings::CreateNonVirtualConferenceJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :high_priority
  application_attr :hearing_schedule
  attr_reader :hearing

  class IncompleteError < StandardError; end
  class HearingRequestCancelled < StandardError; end
  class HearingNotCreatedError < StandardError; end
  class LinkGenerationFailed < StandardError; end

  discard_on(LinkGenerationFailed) do |job, _exception|
    Rails.logger.warn(
      "Discarding #{job.class.name} (#{job.job_id}) because links could not be generated"
    )
  end

  discard_on(HearingRequestCancelled) do |job, _exception|
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
    # job also determines if the hearing creates conference based on that (tests guest/host link present)
    # hearing.guest_link.nil? <== only able to do after Jeff's migrations are in
    # test type of hearing (non-virtual = travel video central) hearing.guest_link.nil?
    # hearing.readable_request_type (works for legacy hearings too)
    # if hearing.determine_service_name == "webex"
    ensure_current_user_is_set
    response = create_conference(hearing)
    hearing.update(
      host_hearing_link: response.host_link,
      co_host_hearing_link: response.co_host_link,
      guest_hearing_link: response.guest_link
    )
  end

  private

  def create_conference(hearing)
    WebexService.new(
      host: ENV["WEBEX_HOST_IC"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_IC"],
      api_endpoint: ENV["WEBEX_API_IC"],
      query: nil
    ).create_conference(hearing)
  end

  def ensure_hearing(hearing)
    fail HearingNotCreatedError if hearing.nil?
    fail HearingRequestCancelled if hearing.cancelled?
  end
end
