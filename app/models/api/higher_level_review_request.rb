# frozen_string_literal: true

# this class, and its subclases, provide:
#
# 1) validation of the *shape and format* of a HLR request json body.
# 2) methods that transform the JSON:API request body to the shape the existing models are expecting
#
# Note:
# only the shape of the data is validated. the goal was to lean on the existing
# validation / verification as much as possible, and only validate the JSON:API shape.
#
# examples:
#
#   * it ensures that a veteran file number is 8 or 9 digits,
#     but does NOT ensure that it refers to an actual veteran file that the user has access to
#
#   * ensures that a date is an actual calendar date, but does not ensure that the date makes
#     sense for where ever it's being used

class HigherLevelReviewRequest
  ATTRIBUTES = %w[
    receipt_date
    informal_conference
    same_office
    legacy_opt_in_approved
    benefit_type
  ].freeze

  attr_reader(*ATTRIBUTES, :veteran, :claimant, :issues)

  def initialize(params)
    data, included = params.as_json.values_at "data", "included"
    type, attributes, relationships = data.values_at "type", "attributes", "relationships"

    fail ArgumentError, "type must be \"HigherLevelReview\"" unless type == "HigherLevelReview"

    initialize_attributes attributes
    initialize_relationships relationships
    initialize_issues included
  end

  def review_params
    ActionController::Parameters.new(
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      receipt_date: receipt_date,
      claimant: claimant&.participant_id,
      veteran_is_not_claimant: !!claimant,
      payee_code: claimant&.payee_code,
      legacy_opt_in_approved: legacy_opt_in_approved
    )
  end

  def complete_params
    ActionController::Parameters.new request_issues: issues.map(&:complete_hash)
  end

  class << self
    def valid_date_format?(date)
      # should be "YYYY-MM-DD"
      Date.valid_date?(*(date.split("-").map { |s| Integer s }))
    end

    def boolean?(arg)
      arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
    end
  end

  private

  def initialize_attributes(attributes)
    ATTRIBUTES.each { |k| instance_variable_set("@#{k}", attributes[k.camelize(:lower)]) }

    fail unless self.class.valid_date_format? receipt_date

    %w[
      informal_conference
      same_office
      legacy_opt_in_approved
    ].each { |k| fail unless self.class.boolean? instance_variable_get "@#{k}" }

    fails unless benefit_type.in? BENEFIT_TYPES.keys
  end

  def initialize_relationships(relationships)
    @veteran = Veteran.new file_number: relationships["veteran"]["data"]["id"]

    # a claimant is optional
    id = relationships.dig("claimant", "data", "id")
    code = relationships.dig("claimant", "data", "meta", "payeeCode")

    if id.present? ^ code.present? # must have both or neither
      fail ArgumentError, "both id and payeeCode are required to specify a claimant"
    end

    @claimant = Claimant.new participant_id: id, payee_code: code if id && code
  end

  def initialize_issues(issues)
    @issues = issues.map do |issue|
      type, id, attributes = issue.values_at "type", "id", "attributes"

      klass = type.camelize + (id ? "Reference" : "")
      fail ArgumentError, "issue type is invalid" unless klass.in? ISSUE_CLASSES

      klass = Object.const_get "HigherLevelReviewRequest::#{klass}"

      attributes = (attributes || {})
        .deep_transform_keys(&:underscore)
        .merge(benefit_type: benefit_type)
        .merge(id ? { id: id } : {})
        .symbolize_keys

      klass.new attributes
    end
  end

  ISSUE_TYPES = %w[
    rating_issue
    nonrating_issue
  ].freeze

  ISSUE_CLASSES = %w[
    RatingIssue
    NonratingIssue
    RatingIssueReference
    NonratingIssueReference
  ].freeze

  file_to_json = lambda do |*path|
    JSON.parse(File.read(File.join(Rails.root, *path)))
  end

  BENEFIT_TYPES = file_to_json["client", "constants", "BENEFIT_TYPES.json"]
  NONRATING_ISSUE_CATEGORIES = file_to_json["client", "constants", "ISSUE_CATEGORIES.json"]

  PAYEE_CODES = %w[
    00
    01
    02
    03
    04
    05
    06
    07
    08
    09
    10
    11
    12
    13
    14
    15
    16
    17
    18
    19
    20
    21
    22
    23
    24
    25
    26
    27
    28
    29
    30
    31
    32
    33
    34
    35
    36
    37
    38
    39
    41
    42
    43
    44
    45
    46
    47
    48
    49
    50
    60
    70
    71
    72
    73
    74
    75
    76
    77
    78
    80
    81
    82
    83
    84
    85
    86
    87
    88
    89
    99
  ].freeze
end
