# frozen_string_literal: true

# for creating a new nonrating issue

class HigherLevelReviewRequest::NonratingIssue < HigherLevelReviewRequest::RatingIssue
  attr_reader(
    :nonrating_issue_category,
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

  undef_method :contested_rating_issue_reference_id
  undef_method :contested_rating_issue_diagnostic_code
  undef_method :rating_issue_reference_id
  undef_method :rating_issue_diagnostic_code

  def initialize(options)
    super options

    @nonrating_issue_category = options[:nonrating_issue_category]
    validate_nonrating_issue_category
  end

  def complete_hash
    { # most of these attributes will always be nil. those that might have a value are noted
      nonrating_issue_category: nonrating_issue_category, # must have a value
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
      edited_description: edited_description
    }
  end

  private

  def validate_nonrating_issue_category
    unless nonrating_issue_category.in?(
      ::HigherLevelReviewRequest::NONRATING_ISSUE_CATEGORIES[benefit_type]
    )
      fail ArgumentError, "that nonrating_issue_category is invalid for that benefit_type"
    end
  end
end
