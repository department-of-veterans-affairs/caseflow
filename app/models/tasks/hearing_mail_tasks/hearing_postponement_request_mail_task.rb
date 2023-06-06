# frozen_string_literal: true

class HearingPostponementRequestMailTask < HearingRequestMailTask
  class << self
    def label
      "Hearing postponement request"
    end

    def allow_creation?(*)
      true
    end
  end
end
