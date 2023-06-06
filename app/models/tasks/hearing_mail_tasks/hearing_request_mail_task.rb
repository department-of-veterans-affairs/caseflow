# frozen_string_literal: true

class HearingRequestMailTask < MailTask
  validates :parent, presence: true, on: :create

  class << self
    def allow_creation?(*)
      false
    end
  end

  def available_actions
    []
  end
end
