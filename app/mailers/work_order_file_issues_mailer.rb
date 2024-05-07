# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
class WorkOrderFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "work_order_file_issues_mailer"

  def send_notification
    mail(subject: subject, to: to_mail)
  end

  private

  def subject
    "Caseflow unable to upload to AWS S3 bucket"
  end

  def to_mail
    case Rails.deploy_env
    when :development, :test
      "Caseflow@test.com"
    when :uat
      "BID_Appeals_UAT@bah.com"
    when :prodtest
      "VHACHABID_Appeals_ProdTest@va.gov"
    when :prod
      "BVAHearingTeam@VA.gov"
    end
  end
end
# rubocop:enable Rails/ApplicationMailer
