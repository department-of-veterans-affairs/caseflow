# frozen_string_literal: true

class RepresentativeHearingEmailRecipient < HearingEmailRecipient
  def self.email_error_message
    "Validation failed: #{RECIPIENT_TITLES[:representative]} email does not appear to be a valid e-mail address"
  end

  validates_email_format_of :email_address, allow_nil: true, message: email_error_message

  def roles
    [RECIPIENT_ROLES[:representative]]
  end
end
