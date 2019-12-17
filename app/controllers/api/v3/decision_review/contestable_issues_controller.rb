# frozen_string_literal: true

class Api::V3::DecisionReview::ContestableIssuesController < Api::V3::BaseController
  before_action :set_veteran_from_header

  def index
    @receipt_date = request.headers["receiptDate"]
    if invalid_receipt_date?
      render_error(
        status: 422,
        code: :bad_receipt_date,
        title: "Bad receipt date"
      )
      return
    end
    issues = ContestableIssueGenerator.new(standin_claim_review).contestable_issues
    render json: Api::V3::ContestableIssueSerializer.new(issues)
  end

  private

  def standin_claim_review
    # this will be refactored to support different decision review types and benefit types
    # currently only supporting HLR for "compensation"; going to have to do this for each type
    @standin_claim_review ||= HigherLevelReview.new(
      veteran_file_number: @veteran.file_number,
      receipt_date: @receipt_date,
      # must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
      benefit_type: "compensation"
    )
  end

  def invalid_receipt_date?
    !@receipt_date.is_a?(Date) ||
      @receipt_date < standin_claim_review.ama_activation_date ||
      Time.zone.today < @receipt_date
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
end
