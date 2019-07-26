# frozen_string_literal: true

class Api::Preintake::RequestIssue
  include Api::Validation

  attr_reader :decision_text, :decision_date, :benefit_type, :notes

  # the kwargs are the only values that can be set (in contrast to all of the fields in complete_hash)
  # must have benefit_type and one of: decision_text, notes
  def initialize(decision_text: nil, decision_date: nil, benefit_type:, notes: nil) # must have benefit_type
    @decision_text = decision_text
    @decision_date = decision_date
    @benefit_type = benefit_type
    @notes = notes
    is_nullable_string? decision_text, key: :decision_text
    is_nullable_date_string? decision_date, key: :decision_date
    is_benefit_type? benefit_type, key: :benefit_type
    is_nullable_string? notes, key: :notes
    any_present? decision_text, notes, keys: [:decision_text, :notes] # must have one
  end

  # used for the "complete" step in the intake form process
  # nils used instead of leaving keys out to be as explicit as possible
  def complete_hash
    {
      decision_text: decision_text,
      decision_date: decision_date,
      benefit_type: benefit_type,
      notes: notes,
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      ramp_claim_id: nil,
      vacols_id: nil,
      vacols_sequence_id: nil,
      contested_decision_issue_id: nil,
      ineligible_reason: nil,
      ineligible_due_to_id: nil,
      edited_description: nil,
    }
  end
end
