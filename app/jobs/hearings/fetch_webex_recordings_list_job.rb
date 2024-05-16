# frozen_string_literal: true

# This job will retrieve a list of webex hearing recordings and details every hour

class Hearings::FetchWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    from = 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour
    to = 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour
    max = 100
    query = "?max=#{max}?from=#{CGI.escape(from.iso8601)}?to=#{CGI.escape(to.iso8601)}"
    error_details = {
      error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
      provider: "webex",
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}#{query}",
      response: { status: exception.code, message: exception.message }.to_json,
      times: { from: from, to: to },
      docket_number: nil
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform
    ensure_current_user_is_set
    fetch_recordings_list.ids.each do |n|
      Hearings::FetchWebexRecordingsDetailsJob.perform_later(id: n)
    end
  end

  def log_error(error)
    super(error, extra: { application: self.class.name, job_id: job_id })
  end

  private

  def fetch_recordings_list
    from = 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour.iso8601
    to = 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour.iso8601
    max = 100
    query = { "from": from, "to": to, "max": max }

    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: CredStash.get("webex_#{Rails.deploy_env}_access_token"),
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).fetch_recordings_list
  end
end
