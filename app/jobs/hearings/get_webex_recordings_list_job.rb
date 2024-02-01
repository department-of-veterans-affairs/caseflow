# frozen_string_literal: true

# This job will get a list of webex recordings made for hearings that have happened
# within 24 hours from the time it is run as well as the details for those recordings

class Hearings::GetWebexRecordingsListJob < ApplicationJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :queue

  class IncompleteError < StandardError; end

  # :nocov:
  retry_on(StandardError, wait: 10.seconds, attempts: 10) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    if job.executions == 10
      kwargs = job.arguments.first
      extra = {
        application: job.class.app_name.to_s,
        appeal_id: kwargs[:appeal_id],
        job_id: job.job_id
      }

      Raven.capture_exception(exception, extra: extra)
    end
  end

  discard_on(ArgumentError)
  # :nocov:

  def perform
    ensure_current_user_is_set

    get_recordings_list.each do |n|
      get_recording_details(n)
    end
  end

  private

  def get_recordings_list
    from = Time.parse("#{Time.zone.today.strftime('%Y-%m-%e')}T21:30:00-05:00")
    to = Time.parse("#{1.day.ago.strftime('%Y-%m-%e')}T21:30:00-05:00")
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
