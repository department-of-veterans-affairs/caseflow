# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
class TranscriptFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "transcript_file_issues"

  # Sends the correct variable data to the template based on environment. Kicks
  # off the template to the above recipients
  def send_issue_details(details, appeal_id)
    @details = details
    @case_link = case Rails.deploy_env
                 when :demo
                   "https://demo.appeals.va.gov/appeals/#{appeal_id}"
                 when :uat
                   "https://appeals.cf.uat.ds.va.gov/queue/appeals/#{appeal_id}"
                 when :prod
                   "https://appeals.cf.ds.va.gov/queue/appeals/#{appeal_id}"
                 when :prodtest
                   "https://appeals.cf.prodtest.ds.va.gov/queue/appeals/#{appeal_id}"
                 when :preprod
                   "https://appeals.cf.preprod.ds.va.gov/queue/appeals/#{appeal_id}"
                 else
                   "localhost:3000/queue/appeals/#{appeal_id}"
                 end
    @subject = "File #{details[:action]} Error - #{details[:provider]} #{details[:docket_number]}"
    mail(subject: @subject, to: to_email_address, cc: cc_email_address) do |format|
      format.html { render "layouts/transcript_file_issues" }
    end
  end

  # Handles specifically the transcript recording list issues
  def webex_recording_list_issues(details)
    @details = details
    @subject = "File #{details[:action]} Error - #{details[:provider]}"
    mail(subject: @subject, to: to_email_address, cc: cc_email_address) do |format|
      format.html { render "layouts/transcript_file_issues" }
    end
  end

  # The email address to send mail to
  def to_email_address
    case Rails.deploy_env
    when :demo, :development, :test
      ""
    when :uat
      "BID_Appeals_UAT@bah.com"
    when :prod
      "BVAHearingTeam@VA.gov"
    end
  end

  # The email address to cc
  def cc_email_address
    "OITAppealsHelpDesk@va.gov" if Rails.deploy_env == :prod
  end
end

# rubocop:enable Rails/ApplicationMailer
