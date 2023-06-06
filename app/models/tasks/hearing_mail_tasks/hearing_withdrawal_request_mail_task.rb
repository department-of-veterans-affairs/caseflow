# frozen_string_literal: true

class HearingWithdrawalRequestMailTask < HearingRequestMailTask
  class << self
    def label
      "Hearing withdrawal request"
    end

    def allow_creation?(*)
      true
    end
  end
end
