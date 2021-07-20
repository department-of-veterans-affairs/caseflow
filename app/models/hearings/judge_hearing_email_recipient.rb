# frozen_string_literal: true

class JudgeHearingEmailRecipient < HearingEmailRecipient
  def role
    RECIPIENT_ROLES[:judge]
  end
end
