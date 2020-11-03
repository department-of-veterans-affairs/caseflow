# frozen_string_literal: true

#  The API (v3) receives ContestableIssues in this shape:
#
#    {
#      type: "ContestableIssue",
#      attributes: {
#        decisionIssueId: integer,
#        ratingIssueReferenceId: string,
#        ratingDecisionReferenceId: string,
#      }
#    }
#
#  and converts them to an /IntakesController-style RequestIssue Parameters object/
#  which can be consumed by the `RequestIssue#attributes_from_intake_data` method.
#  (The API, in general, transforms its data so that it can use the same methods
#  that the IntakesController uses for intaking a DecisionReview.)

class Api::V3::DecisionReviews::ContestableIssueParams
  attr_reader :ids

  def initialize(
    decision_review_class:,
    veteran:,
    receipt_date:,
    benefit_type:,
    params:
  )
    @decision_review_class = decision_review_class
    @veteran = veteran
    @receipt_date = receipt_date
    @benefit_type = benefit_type
    @ids = {
      rating_issue_id: params[:attributes][:ratingIssueReferenceId],
      decision_issue_id: params[:attributes][:decisionIssueId],
      rating_decision_issue_id: params[:attributes][:ratingDecisionReferenceId]
    }
  end

  def contestable_issue
    @contestable_issue ||= unidentified? ? nil : contestable_issue_finder.contestable_issue
  end

  def error_code
    return :contestable_issue_params_must_have_ids if unidentified? # error code
    return nil if contestable_issue_finder.found?

    :could_not_find_contestable_issue # error_code
  end

  # presence of IDs /or/ nonrating_issue_category denotes an identified request issue
  # (nonrating_issue_category isn't supported yet)
  def unidentified?
    @unidentified ||= ids.values.all?(&:blank?)
  end

  # write-in request issues aren't supported at this time
  # unsupported fields:
  #   nonrating_issue_category
  #   notes
  #   untimely_exemption
  #   untimely_exemption_covid
  #   untimely_exemption_notes
  #   vacols_id
  #   vacols_sequence_id
  #   ineligible_reason
  #   ineligible_due_to_id
  #   edited_description
  #   correction_type
  def intakes_controller_params
    ActionController::Parameters.new(
      rating_issue_reference_id: contestable_issue&.rating_issue_reference_id,
      rating_issue_diagnostic_code: contestable_issue&.rating_issue_diagnostic_code,
      rating_decision_reference_id: contestable_issue&.rating_decision_reference_id,
      decision_text: contestable_issue&.description,
      is_unidentified: unidentified?,
      decision_date: contestable_issue&.approx_decision_date,
      benefit_type: @benefit_type,
      ramp_claim_id: contestable_issue&.ramp_claim_id,
      contested_decision_issue_id: contestable_issue&.decision_issue&.id
    )
  end

  private

  def contestable_issue_finder
    @contestable_issue_finder ||= Api::V3::DecisionReviews::ContestableIssueFinder.new(
      {
        decision_review_class: @decision_review_class,
        veteran: @veteran,
        receipt_date: @receipt_date,
        benefit_type: @benefit_type
      }.merge(ids)
    )
  end
end
