# frozen_string_literal: true

class ReviewError < StandardError
  def initialize(intake)
    @intake = intake
    msg = "intake.review!(review_params) did not throw an exception, but did return a falsey value"
    review_errors = @intake&.detail&.errors
    msg = ["#{msg}:", *review_errors.full_messages].join("\n") if review_errors.present?
    super(msg)
  end

  def error_code
    @intake.error_code || :intake_review_failed
  end
end
