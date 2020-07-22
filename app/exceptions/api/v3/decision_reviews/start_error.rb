# frozen_string_literal: true

class Api::V3::DecisionReviews::StartError < StandardError
  attr_reader :error_code

  def initialize(intake)
    @error_code = intake.error_code || :intake_start_failed
    super("intake.start! did not throw an exception, but did return a falsey value")
  end
end
