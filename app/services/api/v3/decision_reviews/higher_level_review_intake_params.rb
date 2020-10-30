# frozen_string_literal: true

class Api::V3::DecisionReviews::HigherLevelReviewIntakeParams
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")

  attr_reader :intake_errors

  def initialize(params)
    @params = params
    @intake_errors = []
    validate
  end

  def intake_errors?
    !@intake_errors.empty?
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      receipt_date: receipt_date,
      informal_conference: attributes["informalConference"],
      same_office: attributes["sameOffice"],
      benefit_type: attributes["benefitType"],
      claimant: claimant_who_is_not_the_veteran["participantId"],
      claimant_type: (veteran_is_not_the_claimant? ? "dependent" : "veteran"),
      payee_code: claimant_who_is_not_the_veteran["payeeCode"],
      legacy_opt_in_approved: attributes["legacyOptInApproved"]
    )
  end

  # params for IntakesController#complete
  def complete_params
    ActionController::Parameters.new(
      request_issues: contestable_issues.map(&:intakes_controller_params)
    )
  end

  def veteran
    @veteran ||= find_veteran
  end

  def attributes
    attributes? ? @params["data"]["attributes"] : {}
  end

  def attributes?
    params? &&
      @params["data"].respond_to?(:has_key?) &&
      @params["data"]["attributes"].respond_to?(:has_key?)
  end

  def params?
    @params.respond_to?(:has_key?)
  end

  def claimant_object_present?
    attributes["claimant"].respond_to?(:has_key?)
  end

  def veteran_is_not_the_claimant?
    claimant_object_present? && !!attributes["claimant"]["participantId"]
  end

  # allows safely calling `claimant_who_is_not_the_veteran["participantId|payeeCode"]`
  # --is not a way to test whether or not the veteran is the claimant.
  # use `veteran_is_not_the_claimant?` for that
  def claimant_who_is_not_the_veteran
    attributes["claimant"] || {}
  end

  def informal_conference_rep?
    !!attributes["informalConferenceRep"]
  end

  def receipt_date
    attributes["receiptDate"] || Time.zone.now.strftime("%F")
  end

  def included
    (params? && @params["included"].is_a?(Array)) ? @params["included"] : []
  end

  def benefit_type_valid?
    attributes["benefitType"].in?(CATEGORIES_BY_BENEFIT_TYPE.keys)
  end

  def shape_valid?
    shape_error_message.nil?
  end

  def shape_error_message
    @shape_error_message ||= describe_shape_error
  end

  def contestable_issues
    @contestable_issues ||= included.map do |contestable_issue_params|
      Api::V3::DecisionReviews::ContestableIssueParams.new(
        decision_review_class: HigherLevelReview,
        veteran: veteran,
        receipt_date: receipt_date,
        benefit_type: attributes["benefitType"],
        params: contestable_issue_params
      )
    end
  rescue StandardError
    @intake_errors << Api::V3::DecisionReviews::IntakeError.new(:malformed_contestable_issues) # error code
    []
  end

  def contestable_issue_intake_errors
    contestable_issues.select(&:error_code).map do |contestable_issue|
      Api::V3::DecisionReviews::IntakeError.new(contestable_issue)
    end
  rescue StandardError
    [Api::V3::DecisionReviews::IntakeError.new(:malformed_contestable_issues)] # error_code
  end

  private

  def find_veteran
    ssn = attributes.dig("veteran", "ssn").to_s.strip

    ssn.present? ? VeteranFinder.find_best_match(ssn) : nil
  end

  def validate
    unless shape_valid?
      @intake_errors << Api::V3::DecisionReviews::IntakeError.new(
        :malformed_request, shape_error_message # error code
      )
      return
    end

    unless benefit_type_valid?
      @intake_errors << Api::V3::DecisionReviews::IntakeError.new(:invalid_benefit_type) # error code
      return
    end

    @intake_errors += contestable_issue_intake_errors
  end

  def describe_shape_error
    return [{ detail: "payload must be an object" }] unless params?

    schema = Rails.root.join(
      "app", "services", "api", "v3", "decision_reviews", "schemas",
      "form_200996_request_higher_level_review_schema.json"
    )
    errors = JSONSchemer.schema(schema).validate(JSON.parse(@params.to_json)).to_a

    unless errors.empty?
      error = Api::V3::DecisionReviews::Errors::SchemerToJsonApiMissingAttribute.new(errors)
      error.all_errors
    end
  end
end
