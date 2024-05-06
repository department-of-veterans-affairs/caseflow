# frozen_string_literal: true

class Hearings::WebexTranscriptionFilesProcessJob < CaseflowJob
  def send_email(error_details)
    TranscriptionFileIssuesMailer.issue_notification(error_details).deliver_now!
  rescue StandardError, Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints
    log_error(error, extra: { application: self.class.name, job_id: job_id })
  end
end
