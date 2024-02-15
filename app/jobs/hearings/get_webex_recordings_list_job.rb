# frozen_string_literal: true

# This job will retrieve a list of webex hearing recordings and details
# in a 24 hours period from the previous day

class Hearings::GetWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
    job.log_error(exception)
  end

  def perform
    ensure_current_user_is_set
    get_recordings_list.ids.each do |n|
      get_recording_details(n)
    end
  end

  def log_error(error)
    Rails.logger.error("Retrying #{self.class.name} because failed with error: #{error}")
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    Raven.capture_exception(error, extra: extra)
  end

  private

  def get_recordings_list
    from = CGI.escape(2.days.ago.in_time_zone("America/New_York").end_of_day.iso8601)
    to = CGI.escape(1.day.ago.in_time_zone("America/New_York").end_of_day.iso8601)
    query = { "from": from, "to": to }

    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).get_recordings_list
  end

  def get_recording_details(id)
    Hearings::GetWebexRecordingsDetailsJob.new(id)
  end
end
