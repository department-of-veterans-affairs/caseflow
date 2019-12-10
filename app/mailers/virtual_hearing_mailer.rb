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
    mail(to: recipient.email, subject: confirmation_subject)
  end

  def confirmation_subject
    case recipient.title
    when RECIPIENT_TITLES[:veteran], RECIPIENT_TITLES[:veteran]
      "Confirmation: Your virtual hearing with the Board of Veterans' Appeals"
    when RECIPIENT_TITLES[:judge]
      "Confirmation: Your virtual hearing"
    end
  end
end
