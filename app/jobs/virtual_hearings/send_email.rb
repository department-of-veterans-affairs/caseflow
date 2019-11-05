# frozen_string_literal: true

module VirtualHearings::SendEmail
  def send_confirmation_emails
    if !virtual_hearing.veteran_email_sent
      send_confirmation_email(:veteran)
      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email_sent
      send_confirmation_email(:judge)
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email_sent
      send_confirmation_email(:representative)
      virtual_hearing.representative_email_sent = true
    end

    virtual_hearing.save
  end

  def send_confirmation_email(recipient)
    VirtualHearingMailer.confirmation(
      mail_recipient: mail_recipients[recipient],
      virtual_hearing: virtual_hearing
    ).deliver_now
  end

  def send_cancellation_emails
    if !virtual_hearing.veteran_email_sent
      send_confirmation_email(:veteran)
      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email_sent
      send_confirmation_email(:judge)
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email_sent
      send_confirmation_email(:representative)
      virtual_hearing.representative_email_sent = true
    end

    virtual_hearing.save
  end

  def send_cancellation_email(recipient)
    VirtualHearingMailer.cancellation(
      mail_recipient: mail_recipients[recipient],
      virtual_hearing: virtual_hearing
    ).deliver_now
  end

  def mail_recipients
    {
      veteran: MailRecipient.new(
        full_name: virtual_hearing.hearing.appeal.veteran.name.to_s,
        email: virtual_hearing.veteran_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:veteran]
      ),
      judge: MailRecipient.new(
        full_name: virtual_hearing.hearing.judge.full_name,
        email: virtual_hearing.judge_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:judge]
      ),
      representative: MailRecipient.new(
        full_name: virtual_hearing.hearing.appeal.representative_name,
        email: virtual_hearing.representative_email,
        title: VirtualHearingMailer::RECIPIENT_TITLES[:representative]
      )
    }
  end
end
