# frozen_string_literal: true

class RepresentativeHearingEmailRecipient < HearingEmailRecipient
  def role
    RECIPIENT_ROLES[:representative]
  end
end
