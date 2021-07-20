# frozen_string_literal: true

class AppellantHearingEmailRecipient < HearingEmailRecipient
  validates :email_address, presence: true, on: [:create, :update]

  def role
    if hearing.appeal.appellant_is_not_veteran
      return RECIPIENT_ROLES[:appellant]
    end

    "veteran"
  end
end
