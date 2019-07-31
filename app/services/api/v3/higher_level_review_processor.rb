# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  attr_reader :intake, :errors

  unless (CATEGORIES_BY_BENEFIT_TYPE = JSON.parse(File.read("client/constants/ISSUE_CATEGORIES.json")))
    fail StandardError, "couldn't pull nonrating issue categories from ISSUE_CATEGORIES.json"
  end

  def initialize(user:, params:)
    @user = user
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

  def build_start_review_complete
    transaction do
      @intake = Intake.build(
        user: @user,
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

  def self.error_from_error_code(code)
    code = code.to_s
    status, title = (
      case code
      when "invalid_file_number"
        [422, "Veteran ID not found"]
      when "veteran_not_found"
        [404, "Veteran not found"]
      when "veteran_has_multiple_phone_numbers"
        [422, "The veteran has multiple active phone numbers"]
      when "veteran_not_accessible"
        [403, "You don't have permission to view this veteran's information"]
      when "veteran_not_modifiable"
        [422, "You don't have permission to intake this veteran"]
      when "veteran_not_valid"
        [422, "The veteran's profile has missing or invalid information required to create an EP."]
      when "duplicate_intake_in_progress"
        [409, "Intake In progress"]
      when "reserved_veteran_file_number"
        [422, "Invalid veteran file number"]
      when "incident_flash"
        [422, "The veteran has an incident flash"]
      else; [nil, nil]
      end
    )
    unless status || title
      status = 422
      title = "Unknown error"
      code = "unknown_error"
    end
    { status: status, code: code, title: title }
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
end
