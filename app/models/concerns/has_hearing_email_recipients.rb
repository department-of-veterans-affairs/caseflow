# frozen_string_literal: true

module HasHearingEmailRecipients
  extend ActiveSupport::Concern

  def appellant_recipient
    AppellantHearingEmailRecipient.find_by(hearing: self)
  end
end
