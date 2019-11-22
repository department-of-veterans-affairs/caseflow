# frozen_string_literal: true

class Api::V3::DecisionReview::ContestableIssuesController < Api::V3::BaseController
  def index
    # REVIEW move these before filters?
    veteran = Veteran.find_by_file_number(request.headers['veteranId'])
    unless veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
      return
    end

    receipt_date = Date.parse(request.headers['receiptDate'])
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
      benefit_type: 'compensation' #must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
    )
    issues = ContestableIssueGenerator.new(standin_claim_review).contestable_issues
    # this generates this error in UAT:
    #  BGS::PublicError (Logon ID APIUSER Not Found in the Benefits Gateway Service (BGS). Contact your ISO if you need assistance gaining access to BGS.)
    byebug
    render json: Api::V3::IssueSerializer.new(issues)
  end

private

  def contestable_issue_data(contestable_issue)
    {
      "decisionText": "veteran status verified",
      "decisionDate": "2019-07-11",
      "category": "Eligibility | Veteran Status",

      "decisionIssueId": contestable_issue.decision_issue&.id

      # these are related to legacy??
      # "ratingIssueId": "12345678",
      # "legacyAppealId": "9876543210",
      # "legacyAppealIssueId": 1
    }.reject{ |_, value| value.nil? }
  end
end
