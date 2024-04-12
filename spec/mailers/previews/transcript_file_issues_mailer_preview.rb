# frozen_string_literal: true

# preview mailer html
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/file_download_issues]
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/file_conversion_issues]
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/file_name_issues]
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/file_upload_issues]
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/webex_recording_list_issues]
#   [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/webex_recording_details_issues]

class TranscriptFileIssuesMailerPreview < ActionMailer::Preview
  def file_download_issues
    details = {
      action: "download",
      action_object: "a mp3 file",
      direction: "from",
      provider: "Webex",
      docket_number: "123456",
      error: Hearings::DownloadTranscriptionFileJob::FileDownloadError,
      download_link: "webex.com/temp_download_link"
    }
    appeal_id = "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    TranscriptFileIssuesMailer.send_issue_details(details, appeal_id)
  end

  def file_conversion_issues
    details = {
      action: "convert",
      action_object: "a vtt file",
      direction: "to",
      conversion_type: "rtf",
      docket_number: "123456",
      error: TranscriptionTransformer::FileConversionError
    }
    appeal_id = "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    TranscriptFileIssuesMailer.send_issue_details(details, appeal_id)
  end

  def file_upload_issues
    details = {
      action: "upload",
      action_object: "a vtt file",
      direction: "to",
      provider: "S3",
      docket_number: "123456",
      error: TranscriptionFileUpload::FileUploadError
    }
    appeal_id = "772f677a-b5fd-45f0-b74d-ecdd15da0730"
    TranscriptFileIssuesMailer.send_issue_details(details, appeal_id)
  end

  def file_name_issues
    details = {
      action: "download",
      action_object: "a file",
      direction: "from",
      provider: "Webex",
      file_name: "240322-2489_441_WrongHearingType.mp3",
      error: Hearings::DownloadTranscriptionFileJob::FileNameError
    }
    TranscriptFileIssuesMailer.send_issue_details(details)
  end

  def webex_recording_list_issues
    from = 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour
    to = 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour

    details = {
      action: "retrieve",
      action_object: "recordings",
      direction: "from",
      provider: "Webex",
      error: Caseflow::Error::WebexApiError,
      api_call: "GET webex.com?max=100?from=#{CGI.escape(from.iso8601)}?to=#{CGI.escape(to.iso8601)}",
      response: { status: 400, message: "Sample error message" }.to_json,
      times: "From: #{from}, To: #{to}"
    }
    TranscriptFileIssuesMailer.send_issue_details(details)
  end

  def webex_recording_details_issues
    recording_id = "12345"
    details = {
      action: "retrieve",
      action_object: "recording details",
      action_object_id: recording_id,
      direction: "from",
      provider: "Webex",
      error: Caseflow::Error::WebexApiError,
      api_call: "GET webex.com/#{recording_id}",
      response: { status: 400, message: "Sample error message" }.to_json
    }
    TranscriptFileIssuesMailer.send_issue_details(details)
  end
end
