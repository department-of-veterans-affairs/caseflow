# frozen_string_literal: true

# This job will retrieve a list of webex hearing recordings and details every hour

class Hearings::FetchWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    from = 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour
    to = 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour
    max = 100
    query = "?max=#{max}?from=#{CGI.escape(from.iso8601)}?to=#{CGI.escape(to.iso8601)}"
    details = {
      action: "retrieve",
      action_object: "recordings",
      direction: "from",
      provider: "Webex",
      error: exception,
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}#{query}",
      response: { status: exception.code, message: exception.message }.to_json,
      docket_number: "N/A",
      times: "From: #{from}, To: #{to}"
    }
    TranscriptFileIssuesMailer.send_issue_details(details)
    job.log_error(exception)
  end

  def perform
    ensure_current_user_is_set
    response = fetch_recordings_list
    topics = response.topics
    topic_num = 0
    response.ids.each do |id|
      Hearings::FetchWebexRecordingsDetailsJob.perform_later(id: id, topic: topics[topic_num])
      topic_num += 1
    end
  end

  def log_error(error)
    super(error, extra: { application: self.class.name, job_id: job_id })
  end

  private

  def fetch_recordings_list
    from = CGI.escape(2.hours.ago.in_time_zone("America/New_York").beginning_of_hour.iso8601)
    to = CGI.escape(1.hour.ago.in_time_zone("America/New_York").beginning_of_hour.iso8601)
    max = 100
    query = { "from": from, "to": to, "max": max }

    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).fetch_recordings_list
  end
end
