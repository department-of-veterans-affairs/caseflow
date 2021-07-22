# frozen_string_literal: true

class JudgeHearingEmailRecipient < HearingEmailRecipient
  def self.email_error_message
    "Validation failed: #{RECIPIENT_TITLES[:judge]} email does not appear to be a valid e-mail address"
  end

  validates_email_format_of :email_address, allow_nil: true, message: email_error_message

  def roles
    [RECIPIENT_ROLES[:judge]]
  end
end
