# frozen_string_literal: true

# This job creates a Webex conference & link for a non virtual hearing

class Hearings::CreateNonVirtualConferenceJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :high_priority
  application_attr :hearing_schedule

  class IncompleteError < StandardError; end
  class HearingRequestCancelled < StandardError; end
  class ConferenceNotCreatedError < StandardError; end
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

  retry_on(VirtualHearingNotCreatedError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  # Retry if Webex returns an invalid response.
  retry_on(Caseflow::Error::WebexApiError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    kwargs = job.arguments.first
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: kwargs[:hearing_id],
      hearing_type: kwargs[:hearing_type]
    }

    Raven.capture_exception(exception, extra: extra)
  end

  def perform
    create_conference(hearing)
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
end
