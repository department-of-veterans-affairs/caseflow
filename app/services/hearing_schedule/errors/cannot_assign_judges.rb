# frozen_string_literal: true

class HearingSchedule::Errors::CannotAssignJudges < HearingSchedule::Errors::StandardErrorWithDetails
  def initialize(message = nil, details = nil)
    super(message, details)
  end
end
