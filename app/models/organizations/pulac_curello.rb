# frozen_string_literal: true

class PulacCurello < Organization
  def self.singleton
    PulacCurello.first || PulacCurello.create(name: Constants.LIT_SUPPORT.PULAC_CURELLO, url: "pulac-curello")
  end

  def next_assignee(_options = {})
    users.first
  end
end
