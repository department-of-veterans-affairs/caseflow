# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  OBJECT = [Hash, ActionController::Parameters, ActiveSupport::HashWithIndifferentAccess]
  BOOL = [true, false]

  INCLUDED_PATH = ["included"]
  LEGACY_APPEAL_ISSUES_PATH = ["attributes", "legacyAppealIssues"]

  def initialize(params)
    @params = params
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      receipt_date: receipt_date,
      informal_conference: attributes["informalConference"],
      same_office: attributes["sameOffice"],
      benefit_type: attributes["benefitType"],
      claimant: claimant_who_is_not_the_veteran["participantId"],
      payee_code: claimant_who_is_not_the_veteran["payeeCode"], 
      veteran_is_not_claimant: veteran_is_not_the_claimant?,
      legacy_opt_in_approved: attributes["legacyOptInApproved"]
    )
  end

  # params for IntakesController#complete
  def complete_params
    ActionController::Parameters.new(
      request_issues: contestable_issues.map(&:intakes_controller_params)
    )
  end

  def errors?
    !errors.empty?
  end

  def errors
    @errors ||= case
                when !shape_valid?
                  [Api::V3::DecisionReview::IntakeError.new(:malformed_request, shape_error_message)]
                when !benefit_type_valid?
                  [Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type)]
                else
                  contestable_issue_errors
                end
  end

  private

  def shape_valid?
    shape_error_message.present?
  end

  def shape_error_message
    @shape_error_message ||= describe_shape_error
  end

  def describe_shape_error
    "payload must be an object" unless @params.respond_to?(:dig)
  
    types_and_paths.find do |(types, path)|
      validator = Api::V3::DecisionReview::HashPathValidator.new(hash: @params, path: path, allowed_values: types)
      break validator.error_msg if !validator.path_is_valid? 
      false
    end
  end

  def attributes
    @params.dig("data", "attributes")
  end

  # most methods are run after `errors` method --this one isn't (hence the paranoia)
  def veteran_is_not_the_claimant?
    @params.respond_to?(:has_key?) &&
      @params["data"].respond_to?(:has_key?) &&
      @params["data"]["attributes"].respond_to?(:has_key?) &&
      !!attributes["claimant"]
  end

  def claimant_who_is_not_the_veteran
    attributes["claimant"] || {}
  end

  def receipt_date
    attributes["receiptDate"] || Time.zone.now.strftime("%F")
  end

  def contestable_issues
    @contestable_issues ||= @params["included"].map do |contestable_issue_params|
      Api::V3::DecisionReview::ContestableIssueParams.new(
        params: contestable_issue_params,
        benefit_type: attributes["benefitType"],
        legacy_opt_in_approved: attributes["legacyOptInApproved"]
      )
    end
  end

  def contestable_issue_errors
    contestable_issues.select(&:error_code).map do |contestable_issue|
      Api::V3::DecisionReview::IntakeError.new(contestable_issue)
    end
  rescue StandardError
    [Api::V3::DecisionReview::IntakeError.new(:malformed_contestable_issues)] # error_code
  end

  def benefit_type_valid?
    attributes["benefitType"].in?(
      Api::V3::DecisionReview::ContestableIssueParams::CATEGORIES_BY_BENEFIT_TYPE.keys
    )
  end

  # array of allowed types (values) for params paths
  def types_and_paths
    [
      [OBJECT,         ["data"]],
      [["HigherLevelReview"], ["data", "type"]],
      [OBJECT,         ["data", "attributes"]],
      [[String, nil],  ["data", "attributes", "receiptDate"]],
      [BOOL,           ["data", "attributes", "informalConference"]],
      [[Array, nil],   ["data", "attributes", "informalConferenceTimes"]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 0]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 1]],
      [[nil],          ["data", "attributes", "informalConferenceTimes", 2]],
      [[*OBJECT, nil], ["data", "attributes", "informalConferenceRep"]],
      [[String],       ["data", "attributes", "informalConferenceRep name"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumber"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberCountryCode"]],
      [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberExt"]],
      [BOOL,           ["data", "attributes", "sameOffice"]],
      [BOOL,           ["data", "attributes", "legacyOptInApproved"]],
      [[String],       ["data", "attributes", "benefitType"]],
      [OBJECT,         ["data", "attributes", "veteran"]],
      [[String],       ["data", "attributes", "veteran", "fileNumberOrSsn"]],
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
        if veteran_is_not_the_claimant? # ... participantId and payeeCode must be present
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
      [[Array],        ["included"]],
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
      *for_array_at_path_enumerate_types_and_paths( # ^^^
        array_path: ["included"],
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
      *legacy_appeal_issues_arrays.reduce([]) do |acc, path| # ^^^
        [
          *acc,
          *for_array_at_path_enumerate_types_and_paths(
            array_path: path,
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

  # returns the paths of all legacyAppealIssues arrays nested in params
  #
  # example return:
  #
  # [
  #   ["included", 0, "legacyAppealIssues"]
  #   ["included", 3, "legacyAppealIssues"]
  #   ["included", 4, "legacyAppealIssues"]
  # ]
  #
  def legacy_appeal_issues_arrays
    @params.dig(*INCLUDED_PATH).each.with_index.reduce([]) do |acc, (contestable_issue, ci_index)|
      next acc unless contestable_issue.dig(*LEGACY_APPEAL_ISSUES_PATH).is_a? Array
  
      [ *acc, [*INCLUDED_PATH, ci_index, *LEGACY_APPEAL_ISSUES_PATH] ]
    end
  rescue
    []
  end

  # given the path to an array, prepends the path of each element of that array
  # to types_and_paths
  #
  # given:
  #
  #   array_path: [:class, :students],
  #
  #   types_and_paths: [
  #     [   [Hash], []            ],
  #     [ [String], [:first_name] ],
  #     [ [String], [:last_name]  ],
  #     [  [Float], [:grade]      ],
  #   ]
  #
  # returns:
  #   [
  #     [   [Hash], [:class, :students, 0]              ],
  #     [ [String], [:class, :students, 0, :first_name] ],
  #     [ [String], [:class, :students, 0, :last_name]  ],
  #     [  [Float], [:class, :students, 0, :grade]      ],
  #     [   [Hash], [:class, :students, 1]              ],
  #     [ [String], [:class, :students, 1, :first_name] ],
  #     [ [String], [:class, :students, 1, :last_name]  ],
  #     [  [Float], [:class, :students, 1, :grade]      ],
  #     [   [Hash], [:class, :students, 2]              ],
  #     [ [String], [:class, :students, 2, :first_name] ],
  #     [ [String], [:class, :students, 2, :last_name]  ],
  #     [  [Float], [:class, :students, 2, :grade]      ],
  #     ...
  #   ]
  def for_array_at_path_enumerate_types_and_paths(array_path:, types_and_paths:)
    array = @params.dig(*array_path)

    array.each.with_index.reduce([]) do |acc, (_, index)|
      [
        *acc,
        *self.class.prepend_path_to_paths(
          prepend_path: [*array_path, index],
          types_and_paths: types_and_paths
        )
      ]
    end
  rescue
    []
  end
 
  # (helper for `for_array_at_path_enumerate_types_and_paths`)
  #
  # given an array (prepend_path), prepends it to each path array in types_and_paths
  #
  # given:
  #
  #   prepend_path: [:data, :attributes],
  #
  #   types_and_paths: [
  #     [   [Hash], []           ],
  #     [ [String], [:name]      ],
  #     [   [Hash], [:coord]     ],
  #     [  [Float], [:coord, :x] ],
  #     [  [Float], [:coord, :y] ],
  #   ]
  #
  # returns:
  #   [
  #     [   [Hash], [:data, :attributes]             ],
  #     [ [String], [:data, :attributes, :name]      ],
  #     [   [Hash], [:data, :attributes, :coord]     ],
  #     [  [Float], [:data, :attributes, :coord, :x] ],
  #     [  [Float], [:data, :attributes, :coord, :y] ],
  #   ]
  def self.prepend_path_to_paths(types_and_paths:, prepend_path:)
    types_and_paths.map do |(types, path)|
      [types, [*prepend_path, *path]]
    end
  end
end
