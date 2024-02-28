# frozen_string_literal: true

class TranscriptFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  default to: "BVAHearingTeam@VA.gov"
  default cc: "OITAppealsHelpDesk@va.gov"
  layout "transcript_file_issues"

  def send_issue_details(details, appeal_id)
    @details = details
    @case_link = case Rails.deploy.env
                 when :demo
                   "https://caseflowdemo.com/queue/appeals/#{appeal_id}"
                 when :staging
                   "https://appeals.cf.uat.ds.va.gov/queue/appeals/#{appeal_id}"
                 when :prod, :prodtest, :preprod
                   "https://appeals.cf.ds.va.gov/queue/appeals/#{appeal_id}"
                 else
                   "localhost:3000/queue/appeals/#{appeal_id}"
                 end
    @subject = "File #{details[:action]} Error - #{details[:provider]} #{details[:docket_number]}"
    mail(subject: @subject) do |format|
      format.html { render "_transcript_file_issues" }
    end
  end

  def webex_recording_list_issues(details)
    @details = details
    @subject = "File #{details[:action]} Error - #{details[:provider]}"
    mail(subject: @subject) do |format|
      format.html { render "_transcript_file_issues" }
    end
  end
end
