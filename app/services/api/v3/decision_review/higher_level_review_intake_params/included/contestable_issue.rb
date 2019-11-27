# frozen_string_literal: true

#  A ContestableIssue received by the API should have this shape:
#
#    {
#      type: "ContestableIssue",
#      attributes: {
#        decisionIssueId
#        ratingIssueId
#        ratingDecisionIssueId
#        legacyAppealIssues
#        ####################### category # tweaked for happy path (no write-in fields)
#        ####################### decisionDate
#        ####################### decisionTexf
#      }
#    }
#
#
#  This class's purpose is
#  1) to ensure a received ContestableIssue (and associated LegacyAppealIssue) is correctly shaped
#  2) convert an API-style ContestableIssue ActionController::Parameters object
#     (see object above) to an IntakesController-style RequestIssue Parameters
#     object:
#
#     {
#       rating_issue_reference_id
# FIX THIS
#       rating_issue_diagnostic_code
#       decision_text
#       decision_date
#       nonrating_issue_category
#       benefit_type
#       notes
#       is_unidentified
#       untimely_exemption
#       untimely_exemption_notes
#       ramp_claim_id
#       vacols_id
#       vacols_sequence_id
#       contested_decision_issue_id
#       ineligible_reason
#       ineligible_due_to_id
#       edited_description
#       correction_type
#     }

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Included::ContestableIssue < Api::V3::DecisionReview::Params
  def self.intakes_controller_style_key(api_style_key)
    API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY[api_style_key] || api_style_key
  end

  # tweaked for happy path
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")
  # CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  KEYS_AND_TYPES = [
    ["decisionIssueId", [Integer, nil]],
    ["ratingIssueId", NULLABLE_STRING],
    ["ratingDecisionIssueId", NULLABLE_STRING],
    ["legacyAppealIssues", [Array, nil]],
    # tweaked for happy path (no write-in fields)
    #   category
    #   decisionDate
    #   decisionText
    # determined to be not useful for our consumers
    #   notes
  ].freeze

  KEYS = KEYS_AND_TYPES.map(&:first)

  API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY = ActiveSupport::HashWithIndifferentAccess.new(
    decisionIssueId: :contested_decision_issue_id,
    ratingIssueId: :rating_issue_reference_id,
    ratingDecisionIssueId: :rating_decision_reference_id,
    legacyAppealId: :vacols_id,
    legacyAppealIssueId: :vacols_sequence_id,
    category: :nonrating_issue_category,
    decisionDate: :decision_date,
    decisionText: :decision_text
  )

  ID_KEYS = [
    :decisionIssueId,
    :ratingIssueId,
    :ratingDecisionIssueId,
  ].freeze

  IDENTIFYING_KEYS = [*ID_KEYS, :category].freeze

  def initialize(params:, benefit_type:, legacy_opt_in_approved:)
    @hash = params.slice(*KEYS)
    @benefit_type = benefit_type
    @hash["legacyAppealIssues"] = initialize_legacy_appeal_issues(legacy_opt_in_approved)
    @errors = Array.wrap(type_error_for_key(*KEYS_AND_TYPES)) +
              legacy_appeal_issue_errors +
              other_errors
  end

  def intakes_controller_params
    hash.as_json.each_with_object(ActionController::Parameters.new) do |(key, value), params|
      params[self.class.intakes_controller_style_key(key)] = value
    end.merge(is_unidentified: unidentified?, benefit_type: @benefit_type)
    # legacy appeal stuff
  end

  def initialize_legacy_appeal_issues(legacy_opt_in_approved)
    legacy_appeal_issues&.map&.with_index do |lai_params, index|
      self.class::LegacyAppealIssue.new(params: lai_params, index: index, legacy_opt_in_approved: legacy_opt_in_approved)
    end
  end

  def legacy_appeal_issues
    hash["legacyAppealIssues"]
  end

  def legacy_appeal_issue_errors
    legacy_appeal_issues&.reduce([]) do |error_array, lai|
      error_array + lai.errors
    end
  end

  def other_errors
    # tweaked for happy path
    Array.wrap(no_ids)
    # Array.wrap(all_fields_are_blank || invalid_category)
  end

  # tweaked for happy path
  # def all_fields_are_blank
  #   return nil if @attributes.values.any?(&:present?)
  #   :request_issue_cannot_be_empty # error_code
  # end

  # tweaked for happy path
  # def invalid_category
  #   return nil if valid_category_for_benefit_type? || @attributes[:category].blank?
  #   :request_issue_category_invalid_for_benefit_type # error_code
  # end
  
  # tweaked for happy path
  # will eventually be replaced by all_fields_are_blank check
  def no_ids
    return nil if hash.slice(*ID_KEYS).values.any?(&:present?)

    :contestable_issue_must_have_at_least_one_ID_field # error_code
  end

  def unidentified?
    @attributes.slice(*IDENTIFYING_KEYS).values.all?(&:blank?)
  end

  # tweaked for happy path
  # def valid_category_for_benefit_type?
  #   hash[:category].in?(CATEGORIES_BY_BENEFIT_TYPE[@benefit_type])
  # end
end
