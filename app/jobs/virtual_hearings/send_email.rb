# frozen_string_literal: true

module VirtualHearings::SendEmail
  attr_reader :virtual_hearing

  def send_emails(virtual_hearing:, type:)
    @virtual_hearing ||= virtual_hearing

    if !virtual_hearing.veteran_email_sent
      send_email(type, :veteran)
      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email_sent
      send_email(type, :judge)
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email_sent
      send_email(type, :representative)
      virtual_hearing.representative_email_sent = true
    end

    virtual_hearing.save
  end

  def send_email(type, recipient)
    if type == :confirmation
      VirtualHearingMailer.confirmation(
        mail_recipient: mail_recipient(recipient),
        virtual_hearing: virtual_hearing
      ).deliver_now
    elsif type == :cancellation
      VirtualHearingMailer.cancellation(
        mail_recipient: mail_recipient(recipient),
        virtual_hearing: virtual_hearing
      ).deliver_now
    end
  end

  def mail_recipient(recipient)
    case recipient
    when :veteran
      veteran_name = virtual_hearing.hearing.appeal.veteran.name
      MailRecipient.new(
        full_name: veteran_name.first_name + " " + veteran_name.last_name,
        email: virtual_hearing.veteran_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:veteran]
      )
    when :judge
      MailRecipient.new(
        full_name: virtual_hearing.hearing.judge.full_name,
        email: virtual_hearing.judge_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:judge]
      )
    when :representative
      MailRecipient.new(
        full_name: virtual_hearing.hearing.appeal.representative_name,
        email: virtual_hearing.representative_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:representative]
      )
    end
  end
end
