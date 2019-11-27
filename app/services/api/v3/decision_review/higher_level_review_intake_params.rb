# frozen_string_literal: true


# top level validation
# make sure there's a data field and an included field

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams < Api::V3::DecisionReview::Params
  # expects ActionController::Parameters
  def initialize(params)
    @hash = params
    @errors = []
    validate
  end

  def errors?
    !errors.empty?
  end

  def veteran_file_number
    veteran[:data][:id].to_s
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      receipt_date: attributes[:receiptDate] || Time.zone.now.strftime("%F"),
      informal_conference: attributes[:informalConference],
      same_office: attributes[:sameOffice],
      benefit_type: attributes[:benefitType],
      claimant: claimant_participant_id,
      payee_code: claimant_payee_code,
      veteran_is_not_claimant: claimant_participant_id.present? || claimant_payee_code.present?,
      legacy_opt_in_approved: legacy_opt_in?
    )
  end

  # params for IntakesController#complete
  def complete_params
    ActionController::Parameters.new(
      request_issues: request_issues.map(&:intakes_controller_params)
    )
  end

  private

  def veteran_shape_valid?
    veteran.respond_to?(:has_key?) &&
      veteran[:data].respond_to?(:has_key?) &&
      veteran[:data][:type] == "Veteran" &&
      veteran[:data][:id].present?
  end

  def claimant
    relationships[:claimant]
  end

  def claimant_shape_valid?
    claimant.respond_to?(:has_key?) &&
      claimant[:data].respond_to?(:has_key?) &&
      claimant[:data][:type] == "Claimant" &&
      claimant[:data][:id].present? &&
      claimant[:data][:meta].respond_to?(:has_key?) &&
      claimant[:data][:meta][:payeeCode].present?
  end

  def claimant_participant_id
    claimant && claimant[:data][:id]
  end

  def claimant_payee_code
    claimant && claimant[:data][:meta][:payeeCode]
  end

  def included
    @params[:included] || []
  end

  def included_shape_valid?
    @params[:included].nil? ||
      (@params[:included].is_a?(Array) && included.all? { |obj| obj.respond_to? :has_key? })
  end

  # remove?
  def legacy_opt_in?
    # tweaked for happy path: legacy_opt_in_approved always true (regardless of input) for happy path
    # attributes[:legacyOptInApproved]
    true
  end

  def request_issues
    @request_issues ||= included
      .select { |obj| obj[:type] == "RequestIssue" }
      .map do |obj|
        Api::V3::DecisionReview::RequestIssueParams.new(
          request_issue: obj,
          benefit_type: attributes[:benefitType],
          legacy_opt_in_approved: legacy_opt_in?
        )
      end
  end

  def minimum_required_shape?
    params_shape_valid? &&
      data_shape_valid? &&
      attributes_shape_valid? &&
      relationships_shape_valid? &&
      veteran_shape_valid?
  end

  def shape_valid?
    minimum_required_shape? &&
      (!claimant || claimant_shape_valid?) &&
      included_shape_valid?
  end

  def validate
    unless shape_valid?
      @errors << Api::V3::DecisionReview::IntakeError.new(:malformed_request)
      return
    end

    unless benefit_type_valid?
      @errors << Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type)
      return
    end

    @errors += request_issue_errors
  end

  def request_issue_errors
    request_issues.select(&:error_code).map do |request_issue|
      Api::V3::DecisionReview::IntakeError.new(request_issue)
    end
  rescue StandardError
    [Api::V3::DecisionReview::IntakeError.new(:malformed_request)]
  end

  def benefit_type_valid?
    attributes[:benefitType].in?(
      Api::V3::DecisionReview::RequestIssueParams::CATEGORIES_BY_BENEFIT_TYPE.keys
    )
  end

  def shape_error
    params_shape_error || data_shape_error || included_shape_error || nil
  end

  def params_shape_error
    @params.respond_to?(:has_key?) ? nil : "Request must be an object."
  end

  def data_shape_error
    case
    when !data.respond_to?(:has_key?)
      '["data"] must be an object'
    when data[:type] != DATA_TYPE
      "[\"data\"][\"type\"] must be #{DATA_TYPE}"
    when !attributes.respond_to?(:has_key?)
      '["data"]["attributes"] must be an object'
    when data.keys.length > 2
      "unknown field(s): #{data.keys.except(:type, :attributes)}"
    else
      attribute_shape_error
    end
  end

  def attributes_shape_error
    case
        when receiptDate
    informalConference
    informalConferenceTimes
    informalConferenceRep
    sameOffice
    legacyOptInApproved
    benefitType
    veteran
    claimant
  end
end
