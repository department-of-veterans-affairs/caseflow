# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  attr_reader :errors

  def initialize(params)
    @params = params
    validate
  end

  def veteran_file_number
    number = relationships.try(:[], :veteran).try(:[], :data).try(:[], :id)
    number && number.to_s
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      informal_conference: attributes.try(:[], :informalConference),
      same_office: attributes.try(:[], :sameOffice),
      benefit_type: attributes.try(:[], :benefitType),
      receipt_date: attributes.try(:[], :receiptDate) || Time.zone.now.strftime("%Y-%m-%d"),
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
    ActionController::Parameters.new(
      request_issues: request_issues.map(&:intakes_controller_params)
    )
  end

  def errors?
    errors.any?
  end

  private

  def attributes
    @params.try(:[], :data).try(:[], :attributes)
  end

  def relationships
    @params.try(:[], :data).try(:[], :relationships)
  end

  def claimant
    relationships.try(:[],:claimant).try(:[],:data)
  end

  def claimant_participant_id
    claimant.try(:[], :id)
  end

  def claimant_payee_code
    claimant.try(:[], :meta).try(:[], :payeeCode)
  end

  def request_issues
    @request_issues ||= (@params.try(:[], :included) || [])
      .select { |obj| obj.respond_to?(:has_key?) && obj[:type] == "RequestIssue" }
      .map do |obj|
        Api::V3::DecisionReview::RequestIssueParams.new(
          request_issue: obj,
          benefit_type: attributes[:benefitType],
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
