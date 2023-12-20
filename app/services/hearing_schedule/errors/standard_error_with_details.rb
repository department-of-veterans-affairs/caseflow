# frozen_string_literal: true

class HearingSchedule::Errors::StandardErrorWithDetails < StandardError
  attr_accessor :details

  def initialize(message = nil, details = nil)
    super(message)
    self.details = details
  end
end
