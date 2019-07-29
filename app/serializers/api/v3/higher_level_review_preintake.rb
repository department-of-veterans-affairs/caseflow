# frozen_string_literal: true

require "json"

class Api::V3::HigherLevelReviewPreintake
  include Api::V3::Concerns::Validation
  SPEC = YAML.safe_load File.read "app/controllers/api/docs/v3/decision_reviews.yaml"

  unless (BENEFIT_TYPES = SPEC.dig(
    "paths",
    "/higher_level_reviews",
    "post",
    "requestBody",
    "content",
    "application/vnd.api+json",
    "schema",
    "properties",
    "data",
    "properties",
    "attributes",
    "properties",
    "benefitType",
    "enum"
  ))
    fail StandardError, "couldn't pull benefit types from decision_reviews.yaml"
  end

  unless (NONRATING_ISSUE_CATEGORIES = JSON.parse(File.read("client/constants/ISSUE_CATEGORIES.json")))
    fail StandardError, "couldn't pull nonrating issue categories from ISSUE_CATEGORIES.json"
  end

  attr_reader(
    :receipt_date,
    :informal_conference,
    :same_office,
    :legacy_opt_in_approved,
    :benefit_type,
    :veteran,
    :claimant,
    :request_issues
  )

  def initialize(hash)
    hash = hash.as_json
    hash? hash
    these_are_the_hash_keys? hash, keys: %w[data included]
    data, included = hash.values_at "data", "included"

    hash? data, name_of_value: "data"
    these_are_the_hash_keys? data, keys: %w[type attributes relationships], name_of_value: "data"
    type, attributes, relationships = data.values_at "type", "attributes", "relationships"

    fail ArgumentError, "type must be HigherLevelReview" unless type == "HigherLevelReview"

    validate_attributes(attributes)
    validate_relationships(relationships)
    validate_included(included)
  end

  def review_params
    ActionController::Parameters.new(
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      receipt_date: receipt_date,
      claimant: claimant&.participant_id,
      veteran_is_not_claimant: !!claimant,
      payee_code: claimant&.payee_code,
      legacy_opt_in_approved: legacy_opt_in_approved
    )
  end

  def complete_params
    ActionController::Parameters.new request_issues: issues.map(&:complete_hash)
  end

  private

  def validate_attributes(attributes)
    hash? attributes, name_of_value: "attributes"
    these_are_the_hash_keys?(
      attributes,
      keys: %w[receiptDate informalConference sameOffice legacyOptInApproved benefitType],
      name_of_value: "attributes"
    )
    @receipt_date, @informal_conference, @same_office, @legacy_opt_in_approved, @benefit_type = (
      attributes.values_at(
        "receiptDate", "informalConference", "sameOffice", "legacyOptInApproved", "benefitType"
      )
    )

    date_string? @receipt_date, name_of_value: "receipt_date"
    boolean? @informal_conference, name_of_value: "informal_conference"
    boolean? @same_office, name_of_value: "same_office"
    boolean? @legacy_opt_in_approved, name_of_value: "legacy_opt_in_approved"
    benefit_type? @benefit_type, name_of_value: "benefit_type"
  end

  def validate_relationships(relationships)
    hash? relationships, name_of_value: "relationships"
    hash_has_at_least_these_keys? relationships, keys: ["veteran"], name_of_value: "relationships"
    hash_keys_are_within_this_set? relationships, keys: ["veteran", "claimant"], name_of_value: "relationships"
    veteran_hash, claimant_hash = relationships.values_at "veteran", "claimant"

    @veteran = Api::V3::VeteranPreintake.new veteran_hash

    return unless relationships.has_key? "claimant"

    @claimant = Claimant.new claimant
  end

  def validate_included(request_issues)
    array? request_issues, name_of_value: "included"
    @request_issues = request_issues.map do |issue|
      Api::V3::RequestIssuePreintake.new(
        hash: issue, benefit_type: benefit_type, legacy_opt_in_approved: legacy_opt_in_approved
      )
    end
  end
end
