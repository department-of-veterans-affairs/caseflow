# frozen_string_literal: true

class Api::DecisionReviewError
  # note: children need to define ERRORS and DEFAULT_ERROR

  attr_reader :status, :title, :code

  # only code needs to be specified. status and title can be specified, but,
  # if they don't match what is pulled up from ERRORS[code], an exception
  # will be thrown
  def initialize(options)
    @status, @title, @code = options.values_at :status, :title, :code
    validate
  end

  def inspect
    { status: status, title: title, code: code }
  end

  delegate :as_json, to: :inspect
  delegate :to_s, to: :inspect

  def render_options
    { json: { errors: as_json }, status: status }
  end

  private

  def validate
    @code ||= DEFAULT_ERROR["code"] # if not specified, use default
    fail ArgumentError, "invalid code: <#{code}>" unless ERRORS[code]

    @title ||= ERRORS[code]["title"] # if unspecified, look it up based off of code's value
    fail ArgumentError, "invalid title: <#{title}>" unless title == ERRORS[code]["title"]

    @status ||= ERRORS[code]["status"]
    @status = @status.to_i # ensure it's numeric
    fail ArgumentError, "invalid status: <#{status}>" unless status == ERRORS[code]["status"]
  end
end
