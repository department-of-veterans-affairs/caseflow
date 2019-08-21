# frozen_string_literal: true

#  A RequestIssue received by the API should have this shape:
#
#    {
#      type: "RequestIssue"
#      attributes: {
#        notes
#        decision_issue_id
#        rating_issue_id
#        legacy_appeal_id
#        legacy_appeal_issue_id
#        category
#        decision_date
#        decision_text
#      }
#    }
#
#
#  This class's purpose is
#  1) to ensure a received RequestIssue is valid
#  2) convert an API-style RequestIssue ActionController::Parameters object
#     (see object above) to an IntakesController-style RequestIssue Parameters
#     object:
#
#     {
#       rating_issue_reference_id
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

class Api::V3::DecisionReview::RequestIssueParams
  # tweaked for happy path
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")
  # CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  PERMITTED_KEYS = [
    :notes,
    :decisionIssueId,
    :ratingIssueId,
    :legacyAppealId,
    :legacyAppealIssueId,
    :category,
    :decisionDate,
    :decisionText
  ].freeze

  API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY = ActiveSupport::HashWithIndifferentAccess.new(
    decisionIssueId: :contested_decision_issue_id,
    ratingIssueId: :rating_issue_reference_id,
    legacyAppealId: :vacols_id,
    legacyAppealIssueId: :vacols_sequence_id,
    category: :nonrating_issue_category
  )

  ID_KEYS = [:decisionIssueId, :ratingIssueId, :legacyAppealId, :legacyAppealIssueId].freeze

  IDENTIFYING_KEYS = [*ID_KEYS, :category].freeze

  attr_reader :error_code

  def initialize(request_issue:, benefit_type:, legacy_opt_in_approved:)
    @attributes = request_issue[:attributes].permit(PERMITTED_KEYS)
    @benefit_type = benefit_type
    @legacy_opt_in_approved = legacy_opt_in_approved
    validate
  end

  def intakes_controller_params
    @attributes.as_json.each_with_object(ActionController::Parameters.new) do |(key, value), params|
      params[self.class.intakes_controller_key(key)] = value
    end.merge(is_unidentified: unidentified?, benefit_type: @benefit_type)
  end

  private

  # sets error_code if there are problems
  def validate
    [:all_fields_are_blank, :invalid_category, :no_ids, :invalid_legacy_fields_or_no_opt_in].each do |test|
      error_code = send test
      if error_code
        @error_code = error_code
        break
      end
    end
  end

  # VALIDATION HELPERS:

  def all_fields_are_blank
    return nil if @attributes.values.any?(&:present?)

    :request_issue_cannot_be_empty # error_code
  end

  def invalid_category
    return nil if valid_category_for_benefit_type? || @attributes[:category].blank?

    :request_issue_category_invalid_for_benefit_type # error_code
  end

  # tweaked for happy path; this error check will be removed post-happy path
  def no_ids
    return nil if @attributes.slice(*ID_KEYS).values.any?(&:present?)

    :request_issue_must_have_at_least_one_ID_field # error_code
  end

  def invalid_legacy_fields_or_no_opt_in
    if legacy_fields_blank? || legacy_fields_present_and_opted_in?
      nil
    elsif @attributes[:legacyAppealIssueId].blank?
      :request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present # error_code
    elsif @attributes[:legacyAppealId].blank?
      :request_issue_legacyAppealId_is_blank_when_legacyAppealIssueId_is_present # error_code
    else
      :request_issue_legacy_not_opted_in # error_code
    end
  end

  # HELPERS:

  def unidentified?
    @attributes.slice(*IDENTIFYING_KEYS).values.all?(&:blank?)
  end

  def valid_category_for_benefit_type?
    @attributes[:category].in?(CATEGORIES_BY_BENEFIT_TYPE[@benefit_type])
  end

  def legacy_fields_blank?
    @attributes[:legacyAppealId].blank? && @attributes[:legacyAppealIssueId].blank?
  end

  def legacy_fields_present_and_opted_in?
    @legacy_opt_in_approved && @attributes[:legacyAppealId].present? && @attributes[:legacyAppealIssueId].present?
  end

  class << self
    def intakes_controller_style_key(api_style_key)
      API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY[api_style_key] || api_style_key
    end
  end
end
