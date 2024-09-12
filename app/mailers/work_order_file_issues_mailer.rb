# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
class WorkOrderFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "work_order_file_issues_mailer"

  MAIL_ADDRESSES = {
    development: "Caseflow@test.com",
    test: "Caseflow@test.com",
    uat: "BID_Appeals_UAT@bah.com",
    prodtest: "VHACHABID_Appeals_ProdTest@va.gov",
    prod: "BVAHearingTeam@VA.gov"
  }.freeze

  def send_notification
    mail(subject: subject, to: to_mail)
  end

  private

  def subject
    "Caseflow unable to upload to AWS S3 bucket"
  end

  def to_mail
    MAIL_ADDRESSES[Rails.deploy_env]
  end
end
# rubocop:enable Rails/ApplicationMailer
