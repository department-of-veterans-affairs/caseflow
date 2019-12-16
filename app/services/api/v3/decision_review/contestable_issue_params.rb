# frozen_string_literal: true

#  The API (v3) receives ContestableIssues in this shape:
#
#    {
#      type: "ContestableIssue",
#      attributes: {
#        decisionIssueId: integer,
#        ratingIssueId: string,
#        ratingDecisionIssueId: string,
#        legacyAppealIssues: [
#          { legacyAppealId: 988, legacyAppealIssueId: 93 },
#          ...
#        ]
#      }
#    }
#
#  and converts them to an /IntakesController-style RequestIssue Parameters object/
#  which can be consumed by the `RequestIssue#attributes_from_intake_data` method.
#  (The API, in general, transforms its data so that it can use the same methods
#  that the IntakesController uses for intaking a DecisionReview.)

class Api::V3::DecisionReview::ContestableIssueParams
  class << self
    def intakes_controller_style_key(api_style_key)
      API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY[api_style_key] || api_style_key
    end
  end

  API_STYLE_KEY_TO_INTAKES_CONTROLLER_STYLE_KEY = ActiveSupport::HashWithIndifferentAccess.new(
    decisionIssueId: :contested_decision_issue_id,
    ratingIssueId: :rating_issue_reference_id,
    ratingDecisionIssueId: :rating_decision_reference_id,
    legacyAppealId: :vacols_id,
    legacyAppealIssueId: :vacols_sequence_id,
    category: :nonrating_issue_category
  )

  # the ContestableIssue's ID fields
  # (legacy appeal IDs (in legacyAppealIssues arrays) are nested within ContestableIssues,
  # but are not ContestableIssue IDs)
  ID_KEYS = [:decisionIssueId, :ratingIssueId, :ratingDecisionIssueId].freeze

  # a RequestIssue is unidentified if it has no ID values nor a category
  IDENTIFYING_KEYS = [*ID_KEYS, :category].freeze

  # category (and other non-ID fields) are not supported for MVP
  PERMITTED_KEYS = [*ID_KEYS, :legacyAppealIssues].freeze

  # only compensation for MVP
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")

  attr_reader :error_code

  def initialize(params:, benefit_type:, legacy_opt_in_approved:)
    @attributes = params[:attributes].slice(*PERMITTED_KEYS)
    # ^^^ params shape / types of fields is mostly checked in IntakeParams (not here)
    @benefit_type = benefit_type
    @legacy_opt_in_approved = legacy_opt_in_approved
    @error_code = determine_error_code
  end

  def intakes_controller_params
    params = ActionController::Parameters.new(
      benefit_type: @benefit_type,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      is_unidentified: unidentified?
    )

    (PERMITTED_KEYS - [:legacyAppealIssues]).each do |api_style_key|
      intakes_controller_style_key = self.class.intakes_controller_style_key(api_style_key)
      params[intakes_controller_style_key] = @attributes[api_style_key]
    end

    params
  end

  private

  # post-MVP, ensure that category is valid for benefit_type
  def determine_error_code
    no_ids_error_code || no_opt_in_error_code || valid_issue
  end

  # For MVP, only the ID fields of request issues are allowed to be populated
  # --no /write-in/ request issues (non-rating issues)
  def no_ids_error_code
    return nil if ids.values.any?(&:present?)

    :contestable_issue_cannot_be_empty # error_code
  end

  def ids
    @attributes.slice(*ID_KEYS)
  end

  def no_opt_in_error_code
    return nil unless legacy_appeal_issues_present?
    return nil if @legacy_opt_in_approved

    :must_opt_in_to_associate_legacy_issues # error_code
  end

  def cant_find_contestable_issue_error_code
    return nil if Api::V3::DecisionReview::LookupContestableIssue.new(ids).valid?

    :cant_find_contestable_issue
  end
    
  def legacy_appeal_issues_present?
    @attributes[:legacyAppealIssues].present?
  end

  def unidentified?
    identifying_fields.values.all?(&:blank?)
  end

  def identifying_fields
    @attributes.slice(*IDENTIFYING_KEYS)
  end

  # for MVP, only one LegacyAppealIssue can be associated with a ContestableIssue
  def vacols_id
    @attributes.dig(:legacyAppealIssues, 0, :legacyAppealId)
  end

  def vacols_sequence_id
    @attributes.dig(:legacyAppealIssues, 0, :legacyAppealIssueId)
  end
end
