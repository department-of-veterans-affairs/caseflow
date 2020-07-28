# frozen_string_literal: true

class Api::V3::DecisionReviews::HigherLevelReviews::ContestableIssuesController < Api::V3::BaseController
  SSN_REGEX = /^\d{9}$/.freeze

  before_action :set_benefit_type_from_url_param, :set_veteran_from_header, :set_receipt_date_from_header

  def index
    render json: { data: serialized_contestable_issues }
  end

  private

  attr_reader :benefit_type, :veteran, :receipt_date

  def serialized_contestable_issues
    contestable_issues.map do |issue|
      Api::V3::ContestableIssueSerializer.new(issue).serializable_hash[:data]
    end
  end

  def contestable_issues
    # for the time being, rating decisions are not being included.
    # rating decisions are actively being discussed / worked on,
    # and promulgation dates can be unreliable (and therefore require a Claims Assistant's interpretation)
    contestable_issue_generator.contestable_rating_issues +
      contestable_issue_generator.contestable_decision_issues
  end

  def contestable_issue_generator
    @contestable_issue_generator ||= ContestableIssueGenerator.new(standin_claim_review)
  end

  def standin_claim_review
    @standin_claim_review ||= HigherLevelReview.new(
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      # must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
      benefit_type: benefit_type
    )
  end

  def veteran_ssn
    @veteran_ssn ||= request.headers["X-VA-SSN"].to_s.strip
  end

  def set_veteran_from_header
    unless veteran_ssn_is_formatted_correctly?
      render_invalid_veteran_ssn
      return
    end

    @veteran = VeteranFinder.find_best_match veteran_ssn
    render_veteran_not_found unless veteran
  end

  def veteran_ssn_is_formatted_correctly?
    !!veteran_ssn.match?(SSN_REGEX)
  end

  def render_invalid_veteran_ssn
    render_errors(
      status: 422,
      code: :invalid_veteran_ssn,
      title: "Invalid Veteran SSN",
      detail: "SSN regex: #{SSN_REGEX.inspect})."
    )
  end

  def render_veteran_not_found
    render_errors(
      status: 404,
      code: :veteran_not_found,
      title: "Veteran Not Found"
    )
  end

  def receipt_date_header
    request.headers["X-VA-Receipt-Date"]
  end

  def set_receipt_date_from_header
    @receipt_date = Date.iso8601 receipt_date_header
    validate_receipt_date # veteran must be set before using this helper
  rescue ArgumentError => error
    raise unless error.message == "invalid date"

    render_invalid_receipt_date
  end

  def validate_receipt_date
    validate_that_receipt_date_is_a_date &&
      validate_that_receipt_date_is_not_before_ama &&
      validate_that_receipt_date_is_not_in_the_future
  end

  def validate_that_receipt_date_is_a_date
    return true if receipt_date.is_a?(Date)

    render_invalid_receipt_date
  end

  def validate_that_receipt_date_is_not_before_ama
    ama_activation_date = standin_claim_review.ama_activation_date
    return true unless receipt_date < ama_activation_date

    render_invalid_receipt_date "is before AMA Activation Date (#{ama_activation_date})."
  end

  def validate_that_receipt_date_is_not_in_the_future
    zone = Time.zone
    today = zone.today
    return true unless receipt_date > today

    render_invalid_receipt_date "is in the future (today: #{today}; time zone: #{zone})."
  end

  def render_invalid_receipt_date(reason = "is not a valid date.")
    render_errors(
      status: 422,
      code: :invalid_receipt_date,
      title: "Invalid Receipt Date",
      detail: "#{receipt_date_header.inspect} #{reason}"
    )
    nil
  end

  def set_benefit_type_from_url_param
    @benefit_type = params[:benefit_type]
    validate_benefit_type
  end

  def validate_benefit_type
    render_invalid_benefit_type unless benefit_type.in? benefit_types
  end

  def benefit_types
    Constants::BENEFIT_TYPES.keys
  end

  def render_invalid_benefit_type
    render_errors(
      status: 422,
      code: :invalid_benefit_type,
      title: "Invalid Benefit Type",
      detail: "Benefit type #{benefit_type.inspect} is invalid. Must be one of: #{benefit_types.inspect}"
    )
  end
end
