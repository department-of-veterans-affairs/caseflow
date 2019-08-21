# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  attr_reader :errors

  def initialize(params)
    @params = params
    validate
  end

  def veteran_file_number
    relationships[:veteran][:data][:id]
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      informal_conference: attributes[:informalConference],
      same_office: attributes[:sameOffice],
      benefit_type: attributes[:benefitType],
      receipt_date: attributes[:receiptDate],
      claimant: claimant_participant_id,
      veteran_is_not_claimant: claimant_participant_id.present? || claimant_payee_code.present?,
      payee_code: claimant_payee_code,
      # tweaked for happy path: legacy_opt_in_approved always true (regardless of input) for happy path
      legacy_opt_in_approved: true
      # legacy_opt_in_approved: attributes[:legacyOptInApproved]
    )
  end

  # params for IntakesController#complete
  def complete_params
    request_issues
  end

  def errors?
    errors.any?
  end

  private

  def attributes
    @params[:data][:attributes]
  end

  def relationships
    @params[:data][:relationships]
  end

  def claimant
    relationships[:claimant][:data]
  end

  def claimant_participant_id
    claimant[:id]
  end

  def claimant_payee_code
    claimant[:meta][:payeeCode]
  end

  def request_issues
    @request_issues ||= @params[:included]
      .select { |obj| obj[:type] == "RequestIssue" }
      .map do |obj|
        Api::V3::DecisionReview::RequestIssueParams.new(
          request_issue: obj,
          benefit_type: attributes[:benefit_type],
          legacy_opt_in_approved: attributes[:legacyOptInApproved]
        )
      end
  end

  def validate
    @errors = request_issues.select(&:error_code).map do |request_issue|
      Api::V3::DecisionReview::IntakeError.new(request_issue)
    end
  end
end
