# frozen_string_literal: true

class Api::V3::DecisionReviews::ReviewError < StandardError
  attr_reader :error_code

  def initialize(intake)
    @error_code = intake.error_code || :intake_review_failed

    msg = "intake.review!(review_params) did not throw an exception, but did return a falsey value"

    review_errors = intake&.detail&.errors
    msg = ["#{msg}:", *review_errors.full_messages].join("\n") if review_errors.present?

    super(msg)
  end
end
