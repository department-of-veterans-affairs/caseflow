# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
class TranscriptFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "transcript_file_issues"

  # Sends the correct variable data to the template based on environment. Kicks
  # off the template to the above recipients
  def send_issue_details(details, appeal_id)
    @details = details
    @deploy_env = Rails.deploy_env
    @config = mailer_config(appeal_id)
    @case_link = @config[:link]
    @subject = "File #{details[:action]} Error - #{details[:provider]} #{details[:docket_number]}"
    mail(subject: @subject, to: @mailer_config[:to_email_address], cc: @mailer_config[:cc_email_address]) do |format|
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

  def mailer_config(appeal_id)
    case @deploy_env
    when :development, :demo, :test
      { link: non_external_link(appeal_id), to_email_address: "Caseflow@test.com" }
    when :uat
      {
        link: "https://appeals.cf.uat.ds.va.gov/queue/appeals/#{appeal_id}",
        to_email_address: "BID_Appeals_UAT@bah.com"
      }
    when :prodtest
      { link: "https://appeals.cf.prodtest.ds.va.gov/queue/appeals/#{appeal_id}" }
    when :preprod
      { link: "https://appeals.cf.preprod.ds.va.gov/queue/appeals/#{appeal_id}" }
    when :prod
      {
        link: "https://appeals.cf.ds.va.gov/queue/appeals/#{appeal_id}",
        to_email_address: "BVAHearingTeam@VA.gov",
        cc_email_address: "OITAppealsHelpDesk@va.gov"
      }
    end
  end

  # The link for the case details page when not in prod or uat
  def non_external_link(appeal_id)
    return "https://demo.appeals.va.gov/appeals/#{appeal_id}" if @deploy_env == "demo"

    "localhost:3000/queue/appeals/#{appeal_id}"
  end
end

# rubocop:enable Rails/ApplicationMailer
