# frozen_string_literal: true

class HigherLevelReviewRequest::Claimant
  attr_reader :participant_id, :payee_code

  def initialize(options)
    @participant_id, @payee_code = options.values_at :participant_id, :payee_code

    fail ArgumentError, "must have a participant_id string" unless participant_id.is_a?(String)
    unless payee_code.in? ::HigherLevelReviewRequest::PAYEE_CODES
      fail ArgumentError, "invalid payee_code string"
    end
  end
end
