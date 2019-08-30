# frozen_string_literal: true
#require "byebug"

class Api::V3::DecisionReview::StartError < StandardError
  attr_reader :error_code

  def initialize(intake)
    #byebug
    @error_code = intake.error_code || :intake_start_failed
    super("intake.start! did not throw an exception, but did return a falsey value")
  end
end
