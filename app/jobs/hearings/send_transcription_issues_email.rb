# frozen_string_literal: true

module Hearings::SendTranscriptionIssuesEmail
  def send_transcription_issues_email(error_details)
    TranscriptionFileIssuesMailer.issue_notification(error_details).deliver_now!
  rescue StandardError, Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints
    log_error(error)
  end
end
