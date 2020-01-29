# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams
  class << self
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
    def prepend_path_to_paths(types_and_paths:, prepend_path:)
      types_and_paths.map do |(types, path)|
        [types, [*prepend_path, *path]]
      end
    end
  end

  OBJECT = [Hash, ActionController::Parameters, ActiveSupport::HashWithIndifferentAccess].freeze
  BOOL = [true, false].freeze

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
      Api::V3::DecisionReview::ContestableIssueParams.new(
        decision_review_class: HigherLevelReview,
        veteran: veteran,
        receipt_date: receipt_date,
        benefit_type: attributes["benefitType"],
        params: contestable_issue_params
      )
    end
  rescue StandardError
    @intake_errors << Api::V3::DecisionReview::IntakeError.new(:malformed_contestable_issues) # error code
    []
  end

  def contestable_issue_intake_errors
    contestable_issues.select(&:error_code).map do |contestable_issue|
      Api::V3::DecisionReview::IntakeError.new(contestable_issue)
    end
  rescue StandardError
    [Api::V3::DecisionReview::IntakeError.new(:malformed_contestable_issues)] # error_code
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
      [[String],       %w[data attributes veteran ssn]],
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
          [OBJECT, []],
          [["ContestableIssue"],   ["type"]],
          [[String, Integer, nil], %w[attributes decisionIssueId]],
          [[String, Integer, nil], %w[attributes ratingIssueId]],
          [[String, Integer, nil], %w[attributes ratingDecisionIssueId]]
        ]
      )
    ]
  end
  # rubocop:enable Metrics/MethodLength

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

  private

  def find_veteran
    ssn = attributes.dig("veteran", "ssn").to_s.strip

    ssn.present? ? VeteranFinder.find_best_match(ssn) : nil
  end

  def validate
    if !shape_valid?
      @intake_errors << Api::V3::DecisionReview::IntakeError.new(
        :malformed_request, shape_error_message # error code
      )
      return
    end

    if !benefit_type_valid?
      @intake_errors << Api::V3::DecisionReview::IntakeError.new(:invalid_benefit_type) # error code
      return
    end

    @intake_errors += contestable_issue_intake_errors
  end

  def describe_shape_error
    return "payload must be an object" unless params?

    validators = types_and_paths.map do |(types, path)|
      Api::V3::DecisionReview::HashPathValidator.new(
        hash: @params,
        path: path,
        allowed_values: types
      )
    end

    validators.find { |validator| !validator.path_is_valid? }&.error_msg
  end
end
