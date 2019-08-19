# frozen_string_literal: true

# A RequestIssue received by the API should have this shape:
#
#   {
#     type: "RequestIssue"
#     attributes: {
#       notes
#       decision_issue_id
#       rating_issue_id
#       legacy_appeal_id
#       legacy_appeal_issue_id
#       category
#       decision_date
#       decision_text
#     }
#   }
#
#
# This class's purpose is
# 1) to ensure a received RequestIssue is valid
# 2) convert an API-style RequestIssue (see object above) to a Parameters object
#    in the format that the IntakesController is expecting:
#
#      {
#        rating_issue_reference_id
#        rating_issue_diagnostic_code
#        decision_text
#        decision_date
#        nonrating_issue_category
#        benefit_type
#        notes
#        is_unidentified
#        untimely_exemption
#        untimely_exemption_notes
#        ramp_claim_id
#        vacols_id
#        vacols_sequence_id
#        contested_decision_issue_id
#        ineligible_reason
#        ineligible_due_to_id
#        edited_description
#        correction_type
#      }

class Api::V3::DecisionReview::RequestIssueParams
  # tweaked for happy path
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")
  # CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  PERMITTED_API_KEYS = [
    :notes,
    :decisionIssueId,
    :ratingIssueId,
    :legacyAppealId,
    :legacyAppealIssueId,
    :category,
    :decisionDate,
    :decisionText
  ].freeze

  API_KEY_TO_INTAKES_CONTROLLER_KEY = ActiveSupport::HashWithIndifferentAccess.new(
    decisionIssueId: :contested_decision_issue_id,
    ratingIssueId: :rating_issue_reference_id,
    legacyAppealId: :vacols_id,
    legacyAppealIssueId: :vacols_sequence_id,
    category: :nonrating_issue_category
  )

  ID_ATTRIBUTES = [:decisionIssueId, :ratingIssueId, :legacyAppealId, :legacyAppealIssueId].freeze

  # if all of these attributes are blank, the RequestIssue is unidentified
  IDENTIFYING_ATTRIBUTES = [*ID_ATTRIBUTES, :category].freeze

  attr_reader :error_code

  def initialize(request_issue, benefit_type, legacy_opt_in_approved)
    @attributes = request_issue[:attributes].permit(PERMITTED_API_KEYS)
    @benefit_type = benefit_type
    @legacy_opt_in_approved = legacy_opt_in_approved
    validate
  end

  def unidentified?(_params)
    @attributes.slice(*IDENTIFYING_ATTRIBUTES).all?(&:blank?)
  end

  def self.api_key_to_intakes_controller_key(key)
    API_KEY_TO_INTAKES_CONTROLLER_KEY[key] || key
  end

  def intakes_controller_params
    @attributes.as_json.each_with_object(ActionController::Parameters.new) do |(key, value), params|
      params[self.class.api_key_to_intakes_controller_key(key)] = value
    end.merge(is_unidentified: unidentified?, benefit_type: @benefit_type)
  end

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

  def all_fields_are_blank
    @attributes.values.all?(&:blank?) ? :request_issue_cannot_be_empty : nil
  end

  def invalid_category
    return nil if @attributes[:category].blank? || @attributes[:category].in?(
      CATEGORIES_BY_BENEFIT_TYPE[@benefit_type]
    )

    :unknown_category_for_benefit_type
  end

  # tweaked for happy path
  # this error condition won't be used post-happy path
  def no_ids(_params)
    return nil if @attributes.slice(*ID_ATTRIBUTES).any?(&:present?)

    :request_issues_without_an_id_are_invalid
  end

  def legacy_fields_both_absent_or_both_present_and_opted_in?
    appeal_id, issue_id = @attributes.slice(:legacyAppealId, :legacyAppealIssueId)
    !!(appeal_id.blank? && issue_id.blank? || appeal_id.present? && issue_id.present? && @legacy_opt_in_approved)
  end

  def self.invalid_legacy_fields_or_no_opt_in
    appeal_id, issue_id = @attributes.slice(:legacyAppealId, :legacyAppealIssueId)
    return nil if legacy_fields_both_absent_or_both_present_and_opted_in?
    return :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id if appeal_id.blank?
    return :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id if issue_id.blank?

    :adding_legacy_issue_without_opting_in
  end
end
