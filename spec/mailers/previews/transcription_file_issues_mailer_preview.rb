# frozen_string_literal: true

# preview mailer html
#   EN
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_upload_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_conversion_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_name_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/webex_rooms_list_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/webex_room_meeting_details_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/webex_recording_list_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/webex_recording_details_issues
class TranscriptionFileIssuesMailerPreview < ActionMailer::Preview
  def file_download_issues
    details = {
      error: { type: "download", explanation: "download a mp3 file from Webex" },
      provider: "webex",
      temporary_download_link: { link: "webex.com/download_link" },
      docket_number: "123456",
      appeal_id: "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def file_upload_issues
    details = {
      error: { type: "upload", explanation: "upload a mp3 file to S3" },
      provider: "S3",
      docket_number: "123456",
      appeal_id: "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def file_conversion_issues
    details = {
      error: { type: "conversion", explanation: "convert a vtt file to rtf" },
      docket_number: "123456",
      appeal_id: "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def file_name_issues
    details = {
      error: { type: "download", explanation: "download a file from Webex" },
      provider: "webex",
      reason: "Unable to parse hearing information from file name: 240322-2489_441_WrongHearingType.mp3",
      expected_file_name_format: "[docket_number]_[internal_id]_[hearing_type].[file_type]",
      docket_number: nil,
      appeal_id: nil
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def webex_rooms_list_issues
    sort_by = "created"
    max = 1000
    query = "?sortBy=#{sort_by}&max=#{max}"

    details = {
      error: { type: "retrieval", explanation: "retrieve a list of rooms from Webex" },
      provider: "webex",
      api_call: "GET https://api-usgov.webex.com/v1/rooms#{query}",
      response: { status: 400, message: "Sample error message" }.to_json
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def webex_room_meeting_details_issues
    room_id = "1234567"
    meeting_title = "221218-977_933_Hearing"
    details = {
      error: { type: "retrieval", explanation: "retrieve a list of room details from Webex" },
      provider: "webex",
      api_call: "GET https://api-usgov.webex.com/v1/rooms/#{room_id}/meetingInfo",
      response: { status: 400, message: "Sample error message" }.to_json,
      room_id: room_id,
      meeting_title: meeting_title
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def webex_recording_list_issues
    max = 100
    meeting_id = "123abc"
    meeting_title = "221218-977_933_Hearing"
    query = "?max=#{max}&meetingId=#{meeting_id}"

    details = {
      error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
      provider: "webex",
      api_call: "GET https://api-usgov.webex.com/v1/admin/recordings/#{query}",
      response: { status: 400, message: "Sample error message" }.to_json,
      meeting_id: "123abc",
      meeting_title: meeting_title
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def webex_recording_details_issues
    recording_id = "12345"
    host_email = "fake@email.com"
    meeting_title = "221218-977_933_Hearing"
    query = "?hostEmail=#{host_email}"
    details = {
      error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
      provider: "webex",
      api_call: "GET https://api-usgov.webex.com/v1/recordings/#{recording_id}#{query}",
      response: { status: 400, message: "Sample error message" }.to_json,
      recording_id: recording_id,
      host_email: host_email,
      meeting_title: meeting_title
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end
end
