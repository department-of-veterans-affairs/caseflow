# frozen_string_literal: true

class VirtualHearings::SendEmail
  attr_reader :virtual_hearing, :type

  def initialize(virtual_hearing:, type:)
    @virtual_hearing = virtual_hearing
    @type = type
  end

  def call
    if !virtual_hearing.veteran_email_sent
      send_email(veteran_recipient)
      virtual_hearing.veteran_email_sent = true
    end

    if should_judge_receive_email?
      send_email(judge_recipient)
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      send_email(representative_recipient)
      virtual_hearing.representative_email_sent = true
    end

    virtual_hearing.save!
  end

  private

  def send_email(recipient)
    case type.to_s
    when "confirmation"
      VirtualHearingMailer.confirmation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    when "cancellation"
      VirtualHearingMailer.cancellation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    when "updated_time_confirmation"
      VirtualHearingMailer.updated_time_confirmation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    else
      fail ArgumentError, "Invalid type of email to send: `#{type}`"
    end

    Rails.logger.info("Sent #{type} email to #{recipient}!")
  end

  def mail_recipients
    {
      veteran: MailRecipient.new(
        name: virtual_hearing.hearing.appeal.veteran&.first_name,
        email: virtual_hearing.veteran_email,
        title: MailRecipient::RECIPIENT_TITLES[:veteran]
      ),
      judge: MailRecipient.new(
        name: virtual_hearing.hearing.judge&.full_name,
        email: virtual_hearing.judge_email,
        title: MailRecipient::RECIPIENT_TITLES[:judge]
      ),
      representative: MailRecipient.new(
        name: virtual_hearing.hearing.appeal.representative_name,
        email: virtual_hearing.representative_email,
        title: MailRecipient::RECIPIENT_TITLES[:representative]
      )
    }

  def judge_recipient
    MailRecipient.new(
      name: virtual_hearing.hearing.judge&.full_name,
      email: virtual_hearing.judge_email,
      title: MailRecipient::RECIPIENT_TITLES[:judge]
    )
  end

  def representative_recipient
    MailRecipient.new(
      name: virtual_hearing.hearing.appeal.representative_name,
      email: virtual_hearing.representative_email,
      title: MailRecipient::RECIPIENT_TITLES[:representative]
    )
  end

  def veteran_recipient
    MailRecipient.new(
      name: virtual_hearing.hearing.appeal.veteran&.first_name,
      email: virtual_hearing.veteran_email,
      title: MailRecipient::RECIPIENT_TITLES[:veteran]
    )
  end

  def should_judge_receive_email?
    !virtual_hearing.judge_email.nil? && !virtual_hearing.judge_email_sent && type != :cancellation
  end
end
