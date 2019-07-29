# frozen_string_literal: true

class Api::V3::RequestIssuePreintake
  include Api::V3::Concerns::Validation

  SPEC = YAML.safe_load File.read "app/controllers/api/docs/v3/decision_reviews.yaml"

  unless PAYEE_CODES = SPEC.dig(
    "components",
    "schemas",
    "payee_code",
    "enum"
  )
    fail StandardError, "couldn't pull payee codes from decision_reviews.yaml"
  end

  attr_reader(
    :notes,
    :decision_id,
    :request_issue_ids,
    :rating_id,
    :legacy_id,
    :benefit_type,
    :category,
    :decision_date,
    :decision_text,
    :legacy_opt_in_approved
  )

  def initialize(hash:, benefit_type: nil, legacy_opt_in_approved: nil)
    @benefit_type = benefit_type # validated only when contesting "other"

    @legacy_opt_in_approved = legacy_opt_in_approved # validated only when contesting "legacy issue"

    hash? hash
    these_are_the_hash_keys? hash, keys: %w[type attributes]
    type, attributes = hash.values_at "type", "attributes"

    fail ArgumentError, "type must be request_issue" unless type == "request_issue"

    hash? attributes
    hash_has_at_least_these_keys? attributes, keys: ["contests"]

    contests = attributes["contests"]
    attributes = attributes.except "contests"

    case contests
    when "on_file_decision" then validate_for_contesting_decision(attributes)
    when "on_file_rating" then validate_for_contesting_rating(attributes)
    when "on_file_legacy_issue" then validate_for_contesting_legacy_issue(attributes)
    when "other" then validate_for_contesting_other(attributes)
    else
      fail ArgumentError, "cannot contest: <#{contests}>"
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

  def validate_for_contesting_decision(attributes)
    hash_has_at_least_these_keys? attributes, keys: %w[notes decision_id]
    hash_keys_are_within_this_set? attributes, keys: %w[notes decision_id request_issue_ids]
    notes, decision_id, request_issue_ids = attributes.values_at "notes", "decision_id", "request_issue_ids"

    string? notes, name_of_value: "notes"
    present? notes, name_of_value: "notes"
    @notes = notes

    int_or_int_string? decision_id, name_of_value: "decision_id"
    @decision_id = to_int decision_id

    nullable_array? request_issue_ids, name_of_value: "request_issue_ids"
    @request_issue_ids = (request_issue_ids || []).map do |id|
      int_or_int_string? id
      to_int id
    end
  end

  def validate_for_contesting_rating(attributes)
    these_are_the_hash_keys? attributes, keys: %w[notes rating_id]
    notes, rating_id = attributes.values_at "notes", "rating_id"

    string? notes, name_of_value: "notes"
    present? notes, name_of_value: "notes"
    @notes = notes

    int_or_int_string? rating_id, name_of_value: "rating_id"
    @rating_id = to_int rating_id
  end

  def validate_for_contesting_legacy_issue(attributes)
    boolean? legacy_opt_in_approved, name_of_value: "legacy_opt_in_approved"

    these_are_the_hash_keys? attributes, keys: %w[notes legacy_id]
    notes, legacy_id = attributes.values_at "notes", "legacy_id"

    true? legacy_opt_in_approved, name_of_value: "legacy_opt_in_approved"

    string? notes, name_of_value: "notes"
    present? notes, name_of_value: "notes"
    @notes = notes

    string? legacy_id, name_of_value: "legacy_id"
    @legacy_id = legacy_id
  end

  def validate_for_contesting_other(attributes)
    benefit_type? benefit_type, name_of_value: "benefit_type"

    hash_has_at_least_these_keys? attributes, keys: %w[notes]
    hash_keys_are_within_this_set? attributes, keys: %w[notes category decision_date decision_text]

    notes, category, decision_date, decision_text = attributes.values_at(
      "notes", "category", "decision_date", "decision_text"
    )

    string? notes, name_of_value: "notes"
    present? notes, name_of_value: "notes"
    @notes = notes

    nullable_nonrating_issue_category_for_benefit_type? category, benefit_type
    @category = category

    nullable_date_string? decision_date, name_of_value: "decision_date"
    @decision_date = decision_date

    nullable_string? decision_text, name_of_value: "decision_text"
    @decision_text = decision_text
  end
end
