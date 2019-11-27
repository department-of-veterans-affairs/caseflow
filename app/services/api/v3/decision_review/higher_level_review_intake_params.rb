# frozen_string_literal: true


# top level validation
# make sure there's a data field and an included field

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams < Api::V3::DecisionReview::Params
  # expects ActionController::Parameters
  def initialize(params)
    @hash = params
    @errors = Array.wrap(
      type_error_for_key(["data", OBJECT], ["included", OBJECT]) ||
      data_errors ||
      included_errors
    )
  end

  # move to data.rb
  def benefit_type_error
    return nil if benefit_type_valid?

    Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type)
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
      request_issues: contestable_issues.map(&:intakes_controller_params)
    )
  end

  private

  def contestable_issues
    @contestable_issues ||= included.map do |obj|
      Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Included::ContestableIssue.new(
        params: obj,
        benefit_type: hash[:data][:benefitType],
        legacy_opt_in_approved: hash[:data][:legacyOptInApproved],
      )
    end
  end

  def contestable_issue_errors
    contestable_issues.select(&:error_code).map do |ci|
      Api::V3::DecisionReview::IntakeError.new(ci)
    end
  rescue StandardError
    [Api::V3::DecisionReview::IntakeError.new(:malformed_request)]
  end

  #move to data.rb
  def benefit_type_valid?
    attributes[:benefitType].in?(
      Api::V3::DecisionReview::RequestIssueParams::CATEGORIES_BY_BENEFIT_TYPE.keys
    )
  end
end
