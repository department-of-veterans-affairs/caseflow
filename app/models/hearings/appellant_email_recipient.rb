# frozen_string_literal: true

class AppellantHearingEmailRecipient < HearingEmailRecipient
  def role
    RECIPIENT_ROLES[:appellant]
  end
end
