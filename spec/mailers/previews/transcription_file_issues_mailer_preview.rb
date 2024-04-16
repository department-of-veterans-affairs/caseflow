# frozen_string_literal: true

# preview mailer html
#   EN
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_upload_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_conversion_issues
#   http://localhost:3000/rails/mailers/transcription_file_issues_mailer/file_name_issues
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

  def webex_recording_list_issues
    from = 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour
    to = 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour
    query = "?max=#100?from=#{CGI.escape(from.iso8601)}?to=#{CGI.escape(to.iso8601)}"

    details = {
      error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
      provider: "webex",
      api_call: "GET webex.com/recordings/list/#{query}",
      response: { status: 400, message: "Sample error message" }.to_json,
      times: { from: from, to: to },
      docket_number: nil
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end

  def webex_recording_details_issues
    recording_id = "12345"
    details = {
      error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
      provider: "webex",
      recording_id: recording_id,
      api_call: "GET webex.com/recordings/details//#{recording_id}",
      response: { status: 400, message: "Sample error message" }.to_json,
      docket_number: nil
    }
    TranscriptionFileIssuesMailer.issue_notification(details)
  end
end
