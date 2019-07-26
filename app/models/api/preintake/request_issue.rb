# frozen_string_literal: true

class Api::Preintake::RequestIssue
  include Api::Validation

  attr_reader(
    :notes,
    :decision_id,
    :request_issue_ids,
    :rating_id,
    :legacy_id,
    :benefit_type,
    :category,
    :decision_date,
    :decision_text
  )

  def initialize(options)
    contests = options["contests"]
    options = options.except "contests"
    case contests
    when "on_file_decision" then validate_for_contesting_decision options
    when "on_file_rating" then validate_for_contesting_rating options
    when "on_file_legacy_issue" then validate_for_contesting_legacy_issue options
    when "other" then validate_for_contesting_other options
    else
      fail ArgumentError, "cannot contest: <#{contests}>" if exception
    end
  end

  # used for the "complete" step in the intake form process
  # nils used instead of leaving keys out to be as explicit as possible
  # TODO: where do request_issue_ids go?
  # rubocop:disable Metrics/MethodLength
  def complete_hash
    identified = benefit_type && category
    {
      rating_issue_reference_id: rating_id,
      rating_issue_diagnostic_code: nil,
      decision_text: decision_text,
      decision_date: decision_date,
      nonrating_issue_category: category,
      benefit_type: benefit_type,
      notes: notes,
      is_unidentified: !identified,
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      ramp_claim_id: nil,
      vacols_id: legacy_id,
      vacols_sequence_id: nil,
      contested_decision_issue_id: decision_id,
      ineligible_reason: nil,
      ineligible_due_to_id: nil,
      edited_description: nil,
      correction_type: nil
    }
  end
  # rubocop:enable Metrics/MethodLength

  private

  def validate_notes(notes)
    is_string? notes, key: :notes
  end

  def validate_id(id, key:)
    is_int_or_int_string? id, key: key
    to_int id
  end

  def validate_for_contesting_decision(options)
    options = options.except "contests"

    # required keys
    hash_has_at_least_these_keys? options, keys: %w[notes decision_id]
    # possible keys
    hash_keys_are_within_this_set? options, keys: %w[notes decision_id request_issue_ids]

    notes, decision_id, request_issue_ids = options.values_at "notes", "decision_id", "request_issue_ids"

    @notes = validate_notes notes

    @decision_id = validate_id decision_id, key: :decision_id

    is_nullable_array? request_issue_ids, key: :request_issue_ids
    @request_issue_ids = request_issue_ids.map do |id|
      is_int_or_int_string? id
      to_int id
    end
  end

  def validate_for_contesting_rating(options)
    options = options.except "contests"

    these_are_the_hash_keys? options, keys: %w[notes rating_id]

    notes, rating_id = options.values_at "notes", "rating_id"

    @notes = validate_notes notes

    @rating_id = validate_id rating_id, key: :rating_id
  end

  def validate_for_contesting_legacy_issue(options)
    options = options.except "contests"

    these_are_the_hash_keys? options, keys: %w[notes legacy_id legacy_opt_in_approved]

    notes, legacy_id, legacy_opt_in_approved = options.values_at "notes", "legacy_id", "legacy_opt_in_approved"

    is_true? legacy_opt_in_approved, key: :legacy_opt_in_approved

    @notes = validate_notes notes

    @legacy_id = validate_id legacy_id, key: :legacy_id
  end

  def validate_for_contesting_other(options)
    options = options.except "contests"

    # required keys
    hash_has_at_least_these_keys? options, keys: %w[notes]
    # possible keys
    hash_keys_are_within_this_set? options, keys: %w[notes benefit_type category decision_date decision_text]

    notes, benefit_type, category, decision_date, decision_text = options.values_at(
      "notes", "benefit_type", "category", "decision_date", "decision_text"
    )
    @notes = validate_notes notes

    is_null_or_benefit_type? @benefit_type = benefit_type, key: :benefit_type

    is_null_or_nonrating_issue_category_for_benefit_type? @category = category, benefit_type

    is_nullable_date_string? @decision_date = decision_date, key: :decision_date

    is_nullable_string? @decision_text = decision_text, key: :decision_text
  end
end
