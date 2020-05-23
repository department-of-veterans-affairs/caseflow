# frozen_string_literal: true

class Api::V3::DecisionReview::ContestableIssuesController < Api::V3::BaseController
  before_action :set_veteran_from_header, :set_receipt_date_from_header

  def index
    render json: { data: serialized_contestable_issues }
  end

  private

  def serialized_contestable_issues
    contestable_issues.map do |issue|
      Api::V3::ContestableIssueSerializer.new(issue).serializable_hash[:data]
    end
  end

  def contestable_issues
    # for the time being, rating decisions are not being included.
    # rating decisions are actively being discussed / worked on,
    # and promulgation dates can be unreliable (and therefore require a Claims Assistant's interpretation)
    ContestableIssueGenerator.new(standin_claim_review).contestable_issues(include_rating_decisions: false)
  end

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

  def render_bad_receipt_date
    render_error(
      status: 422,
      code: :bad_receipt_date,
      title: "Bad receipt date"
    )
  end

  def set_veteran_from_header
    @veteran = VeteranFinder.find_best_match(request.headers["X-VA-SSN"])
    unless @veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
    end
  end

  def set_receipt_date_from_header
    @receipt_date = Date.iso8601(request.headers["X-VA-Receipt-Date"])
    if invalid_receipt_date? # veteran must be set before using this helper
      render_bad_receipt_date
    end
  rescue ArgumentError
    render_bad_receipt_date
  end

  def invalid_receipt_date?
    !@receipt_date.is_a?(Date) ||
      @receipt_date < standin_claim_review.ama_activation_date ||
      Time.zone.today < @receipt_date
  end
end
