# frozen_string_literal: true

module HasHearingEmailRecipientsConcern
  extend ActiveSupport::Concern

  def appellant_recipient
    AppellantHearingEmailRecipient.find_by(hearing: self)
  end
end
