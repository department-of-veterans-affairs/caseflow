# frozen_string_literal: true

# This job will get a list of webex recordings made for hearings that have happened
# within 24 hours from the time it is run as well as the details for those recordings

class Hearings::GetWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    job.log_error(exception)
  end

  def perform
    ensure_current_user_is_set
    fail Caseflow::Error::WebexApiError if !get_recordings_list.success?

    get_recordings_list.ids.each do |n|
      get_recording_details(n)
    end
  end

  def log_error(error)
    Rails.logger.error("#{self.class.name} failed with error: #{error}")
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    Raven.capture_exception(error, extra: extra)
  end

  private

  def get_recordings_list
    from = CGI.escape(Time.parse("#{2.days.ago.strftime('%Y-%m-%d')}T23:59:59-05:00").iso8601)
    to = CGI.escape(Time.parse("#{1.day.ago.strftime('%Y-%m-%d')}T23:59:59-05:00").iso8601)
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
    nil
  end
end
