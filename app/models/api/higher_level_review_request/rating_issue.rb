# frozen_string_literal: true

# for creating a new rating issue

class HigherLevelReviewRequest::RatingIssue < HigherLevelReviewRequest::Notes
  attr_reader(
    :contested_rating_issue_reference_id,
    :contested_rating_issue_diagnostic_code,
    :decision_text,
    :decision_date,
    :benefit_type,
    :untimely_exemption,
    :untimely_exemption_notes,
    :ramp_claim_id,
    :vacols_id,
    :vacols_sequence_id,
    :contested_decision_issue_id,
    :ineligible_reason,
    :ineligible_due_to_id,
    :edited_description
  )

  alias rating_issue_reference_id contested_rating_issue_reference_id
  alias rating_issue_diagnostic_code contested_rating_issue_diagnostic_code

  def initialize(options)
    super options

    @decision_text, @decision_date, @benefit_type = options.values_at(
      :decision_text, :decision_date, :benefit_type
    )

    validate_decision_text
    validate_decision_date
    validate_benefit_type
    validate_that_text_is_present
  end

  def complete_hash
    { # most of these attributes will always be nil. those that might have a value are noted
      rating_issue_reference_id: rating_issue_reference_id,
      rating_issue_diagnostic_code: rating_issue_diagnostic_code,
      decision_text: decision_text, # may have a value
      decision_date: decision_date, # may have a value
      benefit_type: benefit_type, # must have a value
      notes: notes, # may have a value
      untimely_exemption: untimely_exemption,
      untimely_exemption_notes: untimely_exemption_notes,
      ramp_claim_id: ramp_claim_id,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      contested_decision_issue_id: contested_decision_issue_id,
      ineligible_reason: ineligible_reason,
      ineligible_due_to_id: ineligible_due_to_id,
      edited_description: edited_description,
      is_unidentified: true # this is a workaround. otherwise decision_text won't be recorded
    }
  end

  private

  def validate_decision_text
    unless decision_text.nil? || decision_text.is_a?(String)
      fail ArgumentError, "decision_text must be a string"
    end
  end

  def validate_decision_date
    unless ::HigherLevelReviewRequest.valid_date_format?(decision_date)
      fail ArgumentError, "decision_date must be a valid date string: YYYY-MM-DD"
    end
  end

  def validate_benefit_type
    unless ::HigherLevelReviewRequest::BENEFIT_TYPES[benefit_type]
      fail ArgumentError, "benefit_type is invalid: [#{benefit_type}]"
    end
  end

  def validate_that_text_is_present
    if decision_text.nil? && notes.nil?
      fail ArgumentError, "decision_text and notes cannot both be nil"
    end
  end
end
