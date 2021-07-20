# frozen_string_literal: true

class AppellantHearingEmailRecipient < HearingEmailRecipient
  def self.email_error_message
    "Validation failed: #{RECIPIENT_TITLES[:appellant]} email does not appear to be a valid e-mail address"
  end

  # AppellantHearingEmailRecipient cannot have nil email address
  validates :email_address, presence: true, on: [:create, :update]
  validates_email_format_of :email_address, allow_nil: false, :message => email_error_message

  def role
    if hearing.appeal.appellant_is_not_veteran
      return RECIPIENT_ROLES[:appellant]
    end

    "veteran"
  end
end
