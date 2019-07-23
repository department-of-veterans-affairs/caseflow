# frozen_string_literal: true

#
# this class validates the *shape and format* of a HLR request json body.
# it doesn't do any further validation/verification.
# examples:
#   * it ensures that a veteran file number is 8 or 9 digits,
#     but does NOT ensure that it refers to an actual veteran file that the user has access to
#   * ensures that a date is an actual calendar date, but does not ensure that isn't one in the future or
#     one that makes sense for where ever it's being used
#

class LighthouseHigherLevelReviewRequestDeserialized
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

  ATTRIBUTES = %w[
    receipt_date
    informal_conference
    same_office
    legacy_opt_in_approved
    benefit_type
  ].freeze

  ISSUE_TYPES = %w[
    rating_issue
    nonrating_issue
  ].freeze

  ISSUE_CLASSES = %w[
    RatingIssue
    NonratingIssue
    NewRatingIssue
    NewNonratingIssue
  ].freeze

  file_to_json = lambda do |*path|
    JSON.parse(File.read(File.join(Rails.root, *path)))
  end

  BENEFIT_TYPES = file_to_json["client", "constants", "BENEFIT_TYPES.json"]
  NONRATING_ISSUE_CATEGORIES = file_to_json["client", "constants", "ISSUE_CATEGORIES.json"]

  #   BENEFIT_TYPES = %w[
  #     compensation
  #     pension
  #     fiduciary
  #     insurance
  #     education
  #     voc_rehab
  #     loan_guaranty
  #     vha
  #     nca
  #   ]

  # SUBCLASSES

  class Veteran
    attr_reader :file_number

    def initialize(file_number)
      fail unless file_number =~ /^\d{8,9}$/

      @file_number = file_number
    end
  end

  class Claimant
    attr_reader :participant_id, :payee_code

    def initialize(participant_id:, payee_code:)
      fail unless payee_code =~ /\d\d/

      @participant_id = participant_id
      @payee_code = payee_code
    end
  end

  class NewRatingIssue
    attr_reader :decision_text, :decision_date

    def initialize(options)
      text, date = options.values_at :decision_text, :decision_date
      fail unless text.is_a?(String) && ::LighthouseHigherLevelReviewRequestDeserialized.valid_date_format?(date)

      @decision_text = text
      @decision_date = date
    end
  end

  class NewNonratingIssue < NewRatingIssue
    attr_reader :nonrating_issue_category

    def initialize(options)
      # options should have these keys: decision_text, decision_date, nonrating_issue_category, benefit_type
      super options

      category, benefit_type = options.values_at :nonrating_issue_category, :benefit_type
      fail unless category.in? NONRATING_ISSUE_CATEGORIES[benefit_type]

      @nonrating_issue_category = category
    end
  end

  # references an existing a rating issue
  class RatingIssue < NewRatingIssue
    attr_reader :id
    alias contested_rating_issue_reference_id id

    def initialize(options)
      # options should have these keys: decision_text, decision_date, id, notes
      super options

      fail unless (@id = options[:id])
    end
  end

  # references an existing a nonrating issue
  class NonratingIssue < NewNonratingIssue
    attr_reader :id
    alias caseflow_id id

    def initialize(options)
      # options should have these keys: id, decision_text, decision_date, nonrating_issue_category, benefit_type
      super options

      @id = Integer String options[:id]
    end
  end

  # ALL OF THE AVAILABLE INSTANCE METHODS (not counting methods of subclasses)

  attr_reader(*ATTRIBUTES, :veteran, :claimant, :issues)

  def hash_for_review!
    {
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      receipt_date: receipt_date,
      claimant: claimant&.participant_id,
      veteran_is_not_claimant: !!claimant,
      payee_code: claimant&.payee_code,
      legacy_opt_in_approved: legacy_opt_in_approved
    }
  end

  def hash_for_complete!
    {
      request_issues: [
        {
          "benefit_type": "fiduciary",
          "nonrating_issue_category": "Appointment of a Fiduciary (38 CFR 13.100)",
          "decision_text": "ntfoetnoienft",
          "decision_date": "2019-06-09",
          "ineligible_due_to_id": null,
          "ineligible_reason": null,
          "withdrawal_date": null
        }
      ]
    }
  end

  # OTHER METHODS

  def initialize(params)
    data, included = params.as_json.values_at "data", "included"
    type, attributes, relationships = data.values_at "type", "attributes", "relationships"

    fail unless type == "HigherLevelReview"

    initialize_attributes attributes
    initialize_relationships relationships
    initialize_issues included
  end

  private

  def boolean?(arg)
    arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
  end

  def self.valid_date_format?(date)
    # should be "YYYY-MM-DD"
    Date.valid_date?(*(date.split("-").map { |s| Integer s }))
  end

  def initialize_attributes(attributes)
    ATTRIBUTES.each { |k| instance_variable_set("@#{k}", attributes[k.camelize(:lower)]) }

    fail unless self.class.valid_date_format? receipt_date

    %w[
      informal_conference
      same_office
      legacy_opt_in_approved
    ].each { |k| fail unless boolean? instance_variable_get "@#{k}" }

    fails unless benefit_type.in? BENEFIT_TYPES.keys
  end

  def initialize_relationships(relationships)
    @veteran = Veteran.new relationships["veteran"]["data"]["id"]

    # a claimant is optional
    id = relationships.dig("claimant", "data", "id")
    code = relationships.dig("claimant", "data", "meta", "payeeCode")
    fail if !!id ^ !!code # must have both or neither

    @claimant = Claimant.new participant_id: id, payee_code: code if id && code
  end

  def initialize_issues(issues)
    @issues = issues.map do |issue|
      id, attributes = issue.values_at "id", "attributes"

      klass = (id ? "" : "New") + issue["type"].camelize
      fail unless klass.in? ISSUE_CLASSES
      klass = Object.const_get "LighthouseHigherLevelReviewRequestDeserialized::#{klass}"

      attributes = (attributes || {}).deep_transform_keys(&:underscore).merge(benefit_type: benefit_type).merge(id ? { id: id } : {}).symbolize_keys
      klass.new attributes
    end
  end
end
