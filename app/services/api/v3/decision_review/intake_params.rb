# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = []
    validate
  end

  def errors?
    !errors.empty?
  end

  # def veteran_file_number
  #   @params.dig("data", "attributes", "veteran", "fileNumberOrSsn").to_s
  # end

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

  def validate
    unless shape_valid?
      @errors << Api::V3::DecisionReview::IntakeError.new(:malformed_request, shape_error_message)
      return
    end

    unless benefit_type_valid?
      @errors << Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type)
      return
    end

    @errors += contestable_issue_errors
  end

  def shape_valid?
    shape_error_message.present?
  end

  def shape_error_message
    @shape_error_message ||= describe_shape_error
  end

  def describe_shape_error
    "payload must be an object" unless @params.respond_to?(:dig)
  
    types_and_paths.find do |(types, path)|
      validator = HashPathValidator.new(hash: @params, path: path, allowed_values: types)
      break validator.error_msg if !validator.path_is_valid? 
      false
    end
  end

  def included
    @params["included"] || []
  end

  def contestable_issues
    @contestable_issues ||= included
      .select { |obj| obj["type"] == "ContestableIssue" }
      .map do |obj|
        Api::V3::DecisionReview::ContestableIssueParams.new(
          contestable_issue: obj,
          benefit_type: attributes["benefitType"],
          legacy_opt_in_approved: legacy_opt_in?
        )
      end
  end

  def contestable_issue_errors
    contestable_issues.select(&:error_code).map do |contestable_issue|
      Api::V3::DecisionReview::IntakeError.new(contestable_issue)
    end
  rescue StandardError
    [Api::V3::DecisionReview::IntakeError.new(:malformed_contestable_issues)]
  end

  def benefit_type_valid?
    attributes["benefitType"].in?(
      Api::V3::DecisionReview::RequestIssueParams::CATEGORIES_BY_BENEFIT_TYPE.keys
    )
  end

  # array of allowed types (values) for params path
  def types_and_paths
    [
      [OBJECT,         ["data"]], # REQUIRED
      [["HigherLevelReview"], ["data", "type"]],
      [OBJECT,         ["data", "attributes"]], # REQUIRED
      [[String],       ["data", "attributes", "receiptDate"]], # REQUIRED
      [BOOL,           ["data", "attributes", "informalConference"]], # REQUIRED
      [[Array, nil],   ["data", "attributes", "informalConferenceTimes"]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 0]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 1]],
      [[nil],          ["data", "attributes", "informalConferenceTimes", 2]],
      [[*OBJECT, nil], ["data", "attributes", "informalConferenceRep"]],
      [[String],       ["data", "attributes", "informalConferenceRep name"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumber"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberCountryCode"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberCountryCode"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberExt"]],
      [BOOL,           ["data", "attributes", "sameOffice"]], # REQUIRED
      [BOOL,           ["data", "attributes", "legacyOptInApproved"]], # REQUIRED
      [[String],       ["data", "attributes", "benefitType"]], # REQUIRED
      [OBJECT,         ["data", "attributes", "veteran"]], # REQUIRED
      [[String],       ["data", "attributes", "veteran", "fileNumberOrSsn"]], # REQUIRED
      [[String, nil],  ["data", "attributes", "veteran", "addressLine1"]],
      [[String, nil],  ["data", "attributes", "veteran", "addressLine2"]],
      [[String, nil],  ["data", "attributes", "veteran", "city"]],
      [[String, nil],  ["data", "attributes", "veteran", "stateProvinceCode"]],
      [[String, nil],  ["data", "attributes", "veteran", "countryCode"]],
      [[String, nil],  ["data", "attributes", "veteran", "zipPostalCode"]],
      [[String, nil],  ["data", "attributes", "veteran", "phoneNumber"]],
      [[String, nil],  ["data", "attributes", "veteran", "phoneNumberCountryCode"]],
      [[String, nil],  ["data", "attributes", "veteran", "phoneNumberExt"]],
      [[String, nil],  ["data", "attributes", "veteran", "emailAddress"]],
      [[*OBJECT, nil], ["data", "attributes", "claimant"]],
      *(
        if claimant # ... participantId and payeeCode must also be present
          [
            [[String], ["data", "attributes", "claimant", "participantId"]],
            [[String], ["data", "attributes", "claimant", "payeeCode"]],
          ]
        else
          []
        end
      ),
      [[String, nil],  ["data", "attributes", "claimant", "addressLine1"]],
      [[String, nil],  ["data", "attributes", "claimant", "addressLine2"]],
      [[String, nil],  ["data", "attributes", "claimant", "city"]],
      [[String, nil],  ["data", "attributes", "claimant", "stateProvinceCode"]],
      [[String, nil],  ["data", "attributes", "claimant", "countryCode"]],
      [[String, nil],  ["data", "attributes", "claimant", "zipPostalCode"]],
      [[String, nil],  ["data", "attributes", "claimant", "phoneNumber"]],
      [[String, nil],  ["data", "attributes", "claimant", "phoneNumberCountryCode"]],
      [[String, nil],  ["data", "attributes", "claimant", "phoneNumberExt"]],
      [[String, nil],  ["data", "attributes", "claimant", "emailAddress"]],
      [[Array],        ["included"]], # REQUIRED
    # [OBJECT,               ["included", 0]],
    # [["ContestableIssue"], ["included", 0, "type"]],
    # [[Integer, nil],       ["included", 0, "attributes", "decisionIssueId"]],
    # [[String, nil],        ["included", 0, "attributes", "ratingIssueId"]],
    # [[String, nil],        ["included", 0, "attributes", "ratingDecisionIssueId"]],
    # [[Array, nil],         ["included", 0, "attributes", "legacyAppealIssues"]]
    # [OBJECT,               ["included", 1]],
    # [["ContestableIssue"], ["included", 1, "type"]],
    # [[Integer, nil],       ["included", 1, "attributes", "decisionIssueId"]],
    # [[String, nil],        ["included", 1, "attributes", "ratingIssueId"]],
    # [[String, nil],        ["included", 1, "attributes", "ratingDecisionIssueId"]],
    # [[Array, nil],         ["included", 1, "attributes", "legacyAppealIssues"]]
    # ...
      *for_array_at_path_enumerate_types_and_paths(
        path: ["included"],
        types_and_paths: [
          [OBJECT,               []],
          [["ContestableIssue"], ["type"]],
          [[Integer, nil],       ["attributes", "decisionIssueId"]],
          [[String, nil],        ["attributes", "ratingIssueId"]],
          [[String, nil],        ["attributes", "ratingDecisionIssueId"]],
          [[Array, nil],         ["attributes", "legacyAppealIssues"]]
        ]
      ),
    # [OBJECT,   ["included", 2, "attributes", "legacyAppealIssues", 0]]
    # [[String], ["included", 2, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
    # [[String], ["included", 2, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]],
    # [OBJECT,   ["included", 2, "attributes", "legacyAppealIssues", 1]]
    # [[String], ["included", 2, "attributes", "legacyAppealIssues", 1, "legacyAppealId"]],
    # [[String], ["included", 2, "attributes", "legacyAppealIssues", 1, "legacyAppealIssueId"]],
    # [OBJECT,   ["included", 5, "attributes", "legacyAppealIssues", 0]]
    # [[String], ["included", 5, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
    # [[String], ["included", 5, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]],
    # ...
      *legacy_appeal_issue_array_paths.reduce([]) do |acc, path|
        [
          *acc,
          *for_array_at_path_enumerate_types_and_paths(
            path: path,
            types_and_paths: [
              [OBJECT,    []],
              [[String],  ["legacyAppealId"]],
              [[String],  ["legacyAppealIssueId"]],
            ]
          )
        ]
      end
    ]
  end

  def for_array_at_path_enumerate_types_and_paths(array_path, types_and_paths)
    @params.dig(*array_path).each.with_index.reduce([]) do |acc, (_, index)|
      [
        *acc,
        *types_and_paths.map { |(types, path)| [types, [index, *path]] }
      ]
    end
  rescue
    []
  end
  
  def legacy_appeal_issue_array_paths
    included.each.with_index.reduce([]) do |acc, (contestable_issue, ci_index)|
      legacy_appeal_issues = contestable_issue["legacyAppealIssues"]
  
      return acc unless legacy_appeal_issues.is_a? Array
  
      [
        *acc,
        *legacy_appeal_issues.map.with_index do |_, lai_index|
          ["included", ci_index, "legacyAppealIssues", lai_index]
        end
      ]
    end
  rescue
    []
  end
end
