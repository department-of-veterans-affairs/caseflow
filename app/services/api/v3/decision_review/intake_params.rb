# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  OBJECT = [Hash, ActionController::Parameters, ActiveSupport::HashWithIndifferentAccess].freeze
  BOOL = [true, false].freeze

  INCLUDED_PATH = ["included"].freeze
  LEGACY_APPEAL_ISSUES_PATH = %w[attributes legacyAppealIssues].freeze

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
    @errors ||= if !shape_valid?
                  [Api::V3::DecisionReview::IntakeError.new(:malformed_request, shape_error_message)]
                elsif !benefit_type_valid?
                  [Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type)]
                else
                  contestable_issue_errors
                end
  end

  def file_number_or_ssn
    attributes["veteran"]["fileNumberOrSsn"].to_s.strip
  end

  private

  def shape_valid?
    shape_error_message.nil?
  end

  def shape_error_message
    @shape_error_message ||= describe_shape_error
  end

  def describe_shape_error
    return "payload must be an object" unless @params.respond_to?(:dig)

    validators = types_and_paths.map do |(types, path)|
      Api::V3::DecisionReview::HashPathValidator.new(
        hash: @params,
        path: path,
        allowed_values: types
      )
    end

    validators.find { |validator| !validator.path_is_valid? }&.error_msg
  end

  def attributes
    @params.dig("data", "attributes")
  end

  # most methods are run after `errors` method --this one isn't (hence the paranoia)
  def attributes?
    @params.respond_to?(:has_key?) &&
      @params["data"].respond_to?(:has_key?) &&
      @params["data"]["attributes"].respond_to?(:has_key?)
  end

  def claimant_object_present?
    attributes? && attributes["claimant"].respond_to?(:has_key?)
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
    attributes? && !!attributes["informalConferenceRep"]
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
  # rubocop:disable Metrics/MethodLength
  def types_and_paths
    [
      [OBJECT, ["data"]],
      [["HigherLevelReview"], %w[data type]],
      [OBJECT,         %w[data attributes]],
      [[String, nil],  %w[data attributes receiptDate]],
      [BOOL,           %w[data attributes informalConference]],
      [[Array, nil],   %w[data attributes informalConferenceTimes]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 0]],
      [[String, nil],  ["data", "attributes", "informalConferenceTimes", 1]],
      [[nil],          ["data", "attributes", "informalConferenceTimes", 2]],
      [[*OBJECT, nil], %w[data attributes informalConferenceRep]],
      *(
        if informal_conference_rep? # ... name and phoneNumber must be present
          [
            [[String],          %w[data attributes informalConferenceRep name]],
            [[String, Integer], %w[data attributes informalConferenceRep phoneNumber]]
          ]
        else
          []
        end
      ),
      [[String, Integer, nil], %w[data attributes informalConferenceRep phoneNumberCountryCode]],
      [[String, Integer, nil], %w[data attributes informalConferenceRep phoneNumberExt]],
      [BOOL,           %w[data attributes sameOffice]],
      [BOOL,           %w[data attributes legacyOptInApproved]],
      [[String],       %w[data attributes benefitType]],
      [OBJECT,         %w[data attributes veteran]],
      [[String],       %w[data attributes veteran fileNumberOrSsn]],
      [[String, nil],  %w[data attributes veteran addressLine1]],
      [[String, nil],  %w[data attributes veteran addressLine2]],
      [[String, nil],  %w[data attributes veteran city]],
      [[String, nil],  %w[data attributes veteran stateProvinceCode]],
      [[String, nil],  %w[data attributes veteran countryCode]],
      [[String, nil],  %w[data attributes veteran zipPostalCode]],
      [[String, nil],  %w[data attributes veteran phoneNumber]],
      [[String, nil],  %w[data attributes veteran phoneNumberCountryCode]],
      [[String, nil],  %w[data attributes veteran phoneNumberExt]],
      [[String, nil],  %w[data attributes veteran emailAddress]],
      [[*OBJECT, nil], %w[data attributes claimant]],
      *(
        if claimant_object_present? # ... participantId and payeeCode must be present
          [
            [[String], %w[data attributes claimant participantId]],
            [[String], %w[data attributes claimant payeeCode]]
          ]
        else
          []
        end
      ),
      [[String, nil],  %w[data attributes claimant addressLine1]],
      [[String, nil],  %w[data attributes claimant addressLine2]],
      [[String, nil],  %w[data attributes claimant city]],
      [[String, nil],  %w[data attributes claimant stateProvinceCode]],
      [[String, nil],  %w[data attributes claimant countryCode]],
      [[String, nil],  %w[data attributes claimant zipPostalCode]],
      [[String, nil],  %w[data attributes claimant phoneNumber]],
      [[String, nil],  %w[data attributes claimant phoneNumberCountryCode]],
      [[String, nil],  %w[data attributes claimant phoneNumberExt]],
      [[String, nil],  %w[data attributes claimant emailAddress]],
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
          [[Integer, nil],       %w[attributes decisionIssueId]],
          [[String, nil],        %w[attributes ratingIssueId]],
          [[String, nil],        %w[attributes ratingDecisionIssueId]],
          [[Array, nil],         %w[attributes legacyAppealIssues]]
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
      *legacy_appeal_issues_paths.reduce([]) do |acc, path| # ^^^
        [
          *acc,
          *for_array_at_path_enumerate_types_and_paths(
            array_path: path,
            types_and_paths: [
              [OBJECT,    []],
              [[String],  ["legacyAppealId"]],
              [[String],  ["legacyAppealIssueId"]]
            ]
          )
        ]
      end
    ]
  end
  # rubocop:enable Metrics/MethodLength

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
  def legacy_appeal_issues_paths
    @params.dig(*INCLUDED_PATH).each.with_index.reduce([]) do |acc, (contestable_issue, ci_index)|
      if legacy_appeal_issues(contestable_issue).is_a?(Array) && !legacy_appeal_issues(contestable_issue).empty?
        [*acc, [*INCLUDED_PATH, ci_index, *LEGACY_APPEAL_ISSUES_PATH]]
      else
        acc
      end
    end
  rescue StandardError
    []
  end

  def legacy_appeal_issues(contestable_issue)
    contestable_issue.dig(*LEGACY_APPEAL_ISSUES_PATH)
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
  rescue StandardError
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
  class << self
    def prepend_path_to_paths(types_and_paths:, prepend_path:)
      types_and_paths.map do |(types, path)|
        [types, [*prepend_path, *path]]
      end
    end
  end
end
