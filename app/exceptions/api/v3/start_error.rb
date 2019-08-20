# frozen_string_literal: true

class Api::V3::DecisionReview::StartError < StandardError
  def initialize(intake)
    @intake = intake
    super("intake.start! did not throw an exception, but did return a falsey value")
  end

  def error_code
    @intake.error_code || :intake_start_failed
  end
end
