# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "do-not-reply@va.gov"
  layout "mailer"
  attr_reader :recipient

  RECIPIENT_TITLES = {
    judge: "Judge",
    veteran: "Veteran",
    representative: "Representative"
  }.freeze

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    mail(to: recipient.email, subject: "Cancellation Subject")
  end

  def confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    mail(to: recipient.email, subject: "Confirmation Subject")
  end
end
