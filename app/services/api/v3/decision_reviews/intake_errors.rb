# frozen_string_literal: true

# a collection of intake errors
class Api::V3::DecisionReviews::IntakeErrors
  def self.shape_valid?(array)
    array.is_a?(Array) &&
      !array.empty? &&
      array.all? { |element| element.is_a?(Api::V3::DecisionReviews::IntakeError) }
  end

  def initialize(errors)
    unless self.class.shape_valid?(errors)
      fail(
        ArgumentError,
        "must be initialized with a non-empty array of IntakeError elements: <#{errors}>"
      )
    end

    @errors = errors
  end

  def render_hash
    { json: { errors: @errors.map(&:to_h) }, status: status }
  end

  private

  def status
    @errors.map(&:status).max
  rescue StandardError
    500
  end
end
