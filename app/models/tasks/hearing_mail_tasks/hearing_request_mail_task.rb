# frozen_string_literal: true

class HearingRequestMailTask < MailTask
  class << self
    def allow_creation?(*)
      false
    end
  end
end
