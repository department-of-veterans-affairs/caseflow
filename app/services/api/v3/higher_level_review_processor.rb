# frozen_string_literal: true

require "json"

class Api::V3::HigherLevelReviewProcessor
  attr_reader :intake, :errors

  unless (CATEGORIES_BY_BENEFIT_TYPE = JSON.parse(File.read("client/constants/ISSUE_CATEGORIES.json")))
    fail StandardError, "couldn't pull nonrating issue categories from ISSUE_CATEGORIES.json"
  end

  def initialize(_hash)
    @errors = []

    attributes = params[:data][:attributes]
    relationships = params[:data][:relationships]
    included = params[:included]

    @receipt_date = attributes[:receipt_date]
    @informal_conference = attributes[:informal_conference]
    @same_office = attributes[:same_office]
    @legacy_opt_in_approved = attributes[:legacy_opt_in_approved]
    @benefit_type = attributes[:benefit_type]

    @veteran_file_number = relationships[:veteran][:data][:id]

    @claimant_participant_id = relationships.dig :claimant, :data, :id
    @claimant_payee_code = relationships.dig :claimant, :data, :meta, :payeeCode

    @request_issues = included.reduce([]) do |acc, included_item|
      next acc unless included_item[:type] == "RequestIssue"

      request_issue, error = json_api_included_request_issue_to_intake_data_hash(included_item)

      if error
        @errors << error
        next acc
      end

      acc << request_issue
    end
  end

  def errors?
    !errors.empty?
  end

  def build_start_review_complete(current_user)
    transaction do
      @intake = Intake.build(
        user: current_user,
        veteran_file_number: @veteran_file_number,
        form_type: "higher_level_review"
      )

      intake.start!
      intake.review! review_params
      intake.complete! complete_params
    end
  end

  def higher_level_review
    intake.detail
  end

  def self.error_hash_from_error_code(code)
    return ERRORS_BY_CODE[code].merge(code: code) if ERRORS_BY_CODE[code]

    ERRORS_BY_CODE[DEFAULT_ERROR_CODE].merge(code: DEFAULT_ERROR_CODE)
  end

  private

  # returns a 2 element array: [params, error]
  # open question: where will attributes[:request_issue_ids] go?
  def json_api_included_request_issue_to_intake_data_hash(request_issue)
    attributes = request_issue[:attributes]

    if contests == "on_file_legacy_issue" && !@legacy_opt_in_approved
      return [
        nil,
        {
          status: 422,
          title: "Adding legacy issue without opting in",
          code: :adding_legacy_issue_without_opting_in
        }
      ]
    end

    category = attributes[:category]

    unless category.in? CATEGORIES_BY_BENEFIT_TYPE[@benefit_type]
      return [
        nil,
        {
          status: 422,
          title: "Unknown category for benefit type",
          code: :unknown_category_for_benefit_type
        }
      ]
    end

    id = attributes[:id]
    identified = @benefit_type.present? && category.present?

    [
      {
        rating_issue_reference_id: (contests == "on_file_rating_issue") ? id : nil,
        rating_issue_diagnostic_code: nil,
        decision_text: attributes[:decision_text],
        decision_date: attributes[:decision_date],
        nonrating_issue_category: category,
        benefit_type: @benefit_type,
        notes: attributes[:notes],
        is_unidentified: !identified,
        untimely_exemption: nil,
        untimely_exemption_notes: nil,
        ramp_claim_id: nil,
        vacols_id: (contests == "on_file_legacy_issue") ? id : nil,
        vacols_sequence_id: nil,
        contested_decision_issue_id: (contests == "on_file_decision_issue") ? id : nil,
        ineligible_reason: nil,
        ineligible_due_to_id: nil,
        edited_description: nil,
        correction_type: nil
      },
      nil
    ]
  end

  def review_params
    ActionController::Parameters.new(
      informal_conference: @informal_conference,
      same_office: @same_office,
      benefit_type: @benefit_type,
      receipt_date: @receipt_date,
      claimant: @claimant_participant_id,
      veteran_is_not_claimant: @claimant_participant_id.present? || @claimant_payee_code.present?,
      payee_code: @claimant_payee_code,
      legacy_opt_in_approved: @legacy_opt_in_approved
    )
  end

  def complete_params
    ActionController::Parameters.new request_issues: @request_issues
  end

  ERRORS_BY_CODE = lambda do
    # grab our spec
    spec = YAML.safe_load File.read "app/controllers/api/docs/v3/decision_reviews.yaml"
    responses = spec.dig("paths", "/higher_level_reviews", "post", "responses")
    fail StandardError, "couldn't load the responses for HLRs from decision_reviews.yaml" unless responses

    # gather the errors in this format:
    #   [
    #     {"status"=>"404", "title"=>"Veteran File not found", "code"=>"veteran_not_found"},
    #     {"status"=>"422", "title"=>"Unknown error", "code"=>"unknown_error"},
    #     ...
    #   ]
    # and do some validation of decision_reviews.yaml
    errors = responses.reduce([]) do |acc, (status_code, status_body)|
      first_digit_of_status_code = status_code.to_s[0]
      next acc unless first_digit_of_status_code.match?(/4|5/) # skip if response isn't an error

      examples_hash = status_body.dig("content", "application/vnd.api+json", "examples")
      next acc unless examples_hash # skip if there are no examples

      acc + examples_hash.map do |_title, value_hash| # accumulate
        error_hash = value_hash.dig("value", "errors", 0)
        fail StandardError, "invalid error: <#{error_hash}>" unless
            error_hash &&
            error_hash.key?("title") &&
            error_hash.key?("code") &&
            error_hash.key?("status") &&
            (error_hash["status"] = error_hash["status"].to_i) >= 400

        error_hash
      end
    end

    fail StandardError, "decision_reviews.yaml doesn't define any errors for HLRs" if errors.empty?

    # set ERRORS_BY_CODE to this format (lookup by code)
    #   {
    #     "unauthenticated"=>{"status"=>401, "title"=>"Unauthenticated"},
    #     "veteran_not_accessible"=>{"status"=>403, "title"=>"Veteran File inaccessible"},
    #     ...
    #   }
    # validate that an error code is never used more than once
    errors.reduce({}) do |errors_by_code, error_hash|
      code = error_hash["code"]
      fail StandardError, "non-unique error code: <#{code}>" if errors_by_code.key? code

      errors_by_code.merge(code => error_hash.except("code"))
    end
  end.call

  DEFAULT_ERROR_CODE = lambda do
    code = "unknown_error"
    fail StandardError, "???" unless ERRORS_BY_CODE[code]

    code
  end.call
end
