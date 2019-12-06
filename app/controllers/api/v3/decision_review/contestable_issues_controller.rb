# frozen_string_literal: true

class Api::V3::DecisionReview::ContestableIssuesController < Api::V3::BaseController
  def index
    # REVIEW: move these before filters?
    veteran = Veteran.find_by_file_number(request.headers["veteranId"])
    unless veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
      return
    end

    receipt_date = Date.parse(request.headers["receiptDate"])
    if receipt_date < Constants::DATES["AMA_ACTIVATION"].to_date || Date.today < receipt_date
      render_error(
        status: 422,
        code: :bad_receipt_date,
        title: "Bad receipt date"
      )
      return
    end

    # going to have to do this for each type
    standin_claim_review = HigherLevelReview.new(
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: "compensation" # must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
    )
    issues = ContestableIssueGenerator.new(standin_claim_review).contestable_issues
    # this generates this error in UAT:
    #  BGS::PublicError (Logon ID APIUSER Not Found in the Benefits Gateway Service (BGS). Contact your ISO if you need assistance gaining access to BGS.)
    render json: issues.collect { |issue| contestable_issue_data(issue) }
  end

  private

  def contestable_issue_data(contestable_issue)
    attributes = {
      ratingIssueId: contestable_issue.rating_issue_reference_id,
      ratingIssueProfileDate: contestable_issue.rating_issue_profile_date,
      ratingIssueDiagnosticCode: contestable_issue.rating_issue_diagnostic_code,
      description: contestable_issue.description,
      isRating: contestable_issue.is_rating,
      latestIssuesInChain: contestable_issue.latest_contestable_issues.collect { |latest| { id: latest.decision_issue&.id, approxDecisionDate: latest.approx_decision_date } },
      decisionIssueId: contestable_issue.decision_issue&.id,
      ratingDecisionId: contestable_issue.rating_decision_reference_id,
      approxDecisionDate: contestable_issue.approx_decision_date,
      rampClaimId: contestable_issue.ramp_claim_id,
      titleOfActiveReview: contestable_issue.title_of_active_review,
      sourceReviewType: contestable_issue.source_review_type,
      timely: contestable_issue.timely?
    }.reject { |_, value| value.nil? } # REVIEW: should i drop nils?

    {
      type: "ContestableIssue",
      attributes: attributes
    }
  end
end
