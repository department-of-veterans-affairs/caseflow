# frozen_string_literal: true

class Api::V3::DecisionReview::ContestableIssuesController < Api::V3::BaseController
  before_action :set_veteran_from_header

  def index
    @receipt_date = request.headers["receiptDate"]
    if !@receipt_date.is_a?(Date) ||@receipt_date < standin_claim_review.ama_activation_date || Time.zone.today < @receipt_date
      bad_receipt_date
      return
    end
    issues = ContestableIssueGenerator.new(standin_claim_review).contestable_issues
    # this generates this error in UAT:
    #  BGS::PublicError (Logon ID APIUSER Not Found in the Benefits Gateway Service (BGS). Contact your
    #     ISO if you need assistance gaining access to BGS.)
    render json: issues.collect { |issue| contestable_issue_data(issue) }
  end

  private

  def standin_claim_review
    # this will be refactored to support different decision review types and benefit types
    # currently only supporting HLR for "compensation"; going to have to do this for each type
    @standin ||= HigherLevelReview.new(
      veteran_file_number: @veteran.file_number,
      receipt_date: @receipt_date,
      # must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
      benefit_type: "compensation"
    )
  end

  def set_veteran_from_header
    @veteran = Veteran.find_by_file_number(request.headers["veteranId"])
    unless @veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
    end
  end

  def bad_receipt_date
    render_error(
      status: 422,
      code: :bad_receipt_date,
      title: "Bad receipt date"
    )
  end

  def contestable_issue_data(contestable_issue)
    latest_issues_in_chain =
      contestable_issue.latest_contestable_issues.collect do |latest|
        { id: latest.decision_issue&.id, approxDecisionDate: latest.approx_decision_date }
      end
    attributes = {
      ratingIssueId: contestable_issue.rating_issue_reference_id,
      ratingIssueProfileDate: contestable_issue.rating_issue_profile_date,
      ratingIssueDiagnosticCode: contestable_issue.rating_issue_diagnostic_code,
      description: contestable_issue.description,
      isRating: contestable_issue.is_rating,
      latestIssuesInChain: latest_issues_in_chain,
      decisionIssueId: contestable_issue.decision_issue&.id,
      ratingDecisionId: contestable_issue.rating_decision_reference_id,
      approxDecisionDate: contestable_issue.approx_decision_date,
      rampClaimId: contestable_issue.ramp_claim_id,
      titleOfActiveReview: contestable_issue.title_of_active_review,
      sourceReviewType: contestable_issue.source_review_type,
      timely: contestable_issue.timely?
    }.compact

    { type: "ContestableIssue", attributes: attributes }
  end
end
