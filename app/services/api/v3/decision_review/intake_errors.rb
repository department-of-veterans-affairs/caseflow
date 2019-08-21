# frozen_string_literal: true

# a collection of intake errors
class Api::V3::DecisionReview::IntakeErrors
  def initialize(errors)
    unless errors.is_a?(Array) && errors.any?
      fail ArgumentError, "an IntakeErrors object must be initialized with a non-empty array"
    end

    @errors = errors
  end

  def render_hash
    { json: { errors: @errors }, status: status }
  end

  private

  def status
    statuses.max
  end

  def statuses
    @errors.each_with_object([]) do |error, statuses|
      status = error&.status
      next unless status

      statuses.push(Integer(status || 422))
    end
  end
end
