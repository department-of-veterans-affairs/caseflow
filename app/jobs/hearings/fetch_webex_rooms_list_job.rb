# frozen_string_literal: true

# This job will retrieve a list of all the webex meeting rooms used by the VA to hold hearings

class Hearings::FetchWebexRoomsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail
  include WebexConcern

  queue_with_priority :low_priority
  application_attr :hearings_schedule

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    sort_by = "created"
    max = 1000
    query = "?sortBy=#{sort_by}&max=#{max}"
    error_details = {
      error: { type: "retrieval", explanation: "retrieve a list of rooms from Webex" },
      provider: "webex",
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}rooms#{query}",
      response: { status: exception.code, message: exception.message }.to_json
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform
    ensure_current_user_is_set
    fetch_rooms_list.rooms.each do |room|
      title = filter_title(room.title).first
      next if title.blank?

      Hearings::FetchWebexRoomMeetingDetailsJob.perform_later(room_id: room.id, meeting_title: title)
    end
  end

  def log_error(error)
    super(error, extra: { application: self.class.name, job_id: job_id })
  end

  private

  def filter_title(title)
    title.scan(/\d*-*\d+_\d+_[A-Za-z]*Hearing/)
  end

  def fetch_rooms_list
    sort_by = "created"
    max = 1000
    query = { "sortBy": sort_by, "max": max }

    WebexService.new(rooms_config(query)).fetch_rooms_list
  end
end
