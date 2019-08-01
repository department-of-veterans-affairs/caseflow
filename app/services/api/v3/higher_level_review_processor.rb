# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  attr_reader :intake, :errors

  ERROR_STATUSES_AND_TITLES_BY_CODE = {
    invalid_file_number: { status: 422, title: "Veteran ID not found" },
    veteran_not_found: { status: 404, title: "Veteran not found" },
    veteran_has_multiple_phone_numbers: { status: 422, title: "The veteran has multiple active phone numbers" },
    veteran_not_accessible: { status: 403, title: "You don't have permission to view this veteran's information" },
    veteran_not_modifiable: { status: 422, title: "You don't have permission to intake this veteran" },
    veteran_not_valid: {
      status: 422, title: "The veteran's profile has missing or invalid information required to create an EP."
    },
    duplicate_intake_in_progress: { status: 409, title: "Intake In progress" },
    reserved_veteran_file_number: { status: 422, title: "Invalid veteran file number" },
    incident_flash: { status: 422, title: "The veteran has an incident flash" },
    adding_legacy_issue_without_opting_in: { status: 422, title: "Adding legacy issue without opting in" },
    unknown_category_for_benefit_type: { status: 422, title: "Unknown category for benefit type" }
  }.freeze

  DEFAULT_ERROR = { status: 422, code: :unknown_error, title: "Unknown error" }.freeze

  unless (CATEGORIES_BY_BENEFIT_TYPE = JSON.parse(File.read("client/constants/ISSUE_CATEGORIES.json")))
    fail StandardError, "couldn't pull nonrating issue categories from ISSUE_CATEGORIES.json"
  end

  def initialize(params, user)
    @user = user
    @errors = []
    @request_issues = []

    attributes = params[:data][:attributes]
    relationships = params[:data][:relationships]
    included = params[:included]

    @receipt_date = attributes[:receiptDate]
    @informal_conference = attributes[:informalConference]
    @same_office = attributes[:sameOffice]
    @legacy_opt_in_approved = attributes[:legacyOptInApproved]
    @benefit_type = attributes[:benefitType]
    @veteran_file_number = relationships[:veteran][:data][:id]
    @claimant_participant_id = relationships.dig :claimant, :data, :id
    @claimant_payee_code = relationships.dig :claimant, :data, :meta, :payeeCode

    @request_issues = included.each do |hash|
      next unless hash[:type] == "RequestIssue"

      request_issue, error = included_request_issue_to_intake_data_hash(hash, legacy_opt_in_approved, benefit_type)
      @errors << error if error
      @request_issues << request_issue if request_issue
    end
  end

  def errors?
    !errors.empty?
  end

  def build_start_review_complete!
    @intake = Intake.build(
      user: @user,
      veteran_file_number: @veteran_file_number,
      form_type: "higher_level_review"
    )
    transaction do
      intake.start!
      intake.review! review_params
      intake.complete! complete_params
    end
  end

  def higher_level_review
    intake.detail
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

  class << self
    def error_from_error_code(code)
      return DEFAULT_ERROR unless code

      status_and_title = ERROR_STATUSES_AND_TITLES_BY_CODE[code.to_sym]
      return DEFAULT_ERROR unless status_and_title

      { status: status_and_title[:status], code: code, title: status_and_title[:title] }
    end

    # open question: where will attributes[:request_issue_ids] go?
    def included_request_issue_to_intake_data_hash(request_issue, legacy_opt_in_approved, benefit_type)
      attributes = request_issue[:attributes]

      if attributes[:contests] == "on_file_legacy_issue" && !legacy_opt_in_approved
        return [nil, error_from_error_code(:adding_legacy_issue_without_opting_in)]
      end

      unless attributes[:category].in? CATEGORIES_BY_BENEFIT_TYPE[benefit_type]
        return [nil, error_from_error_code(:unknown_category_for_benefit_type)]
      end

      [intake_data_hash(attributes.merge(benefit_type: benefit_type)), nil]
    end

    private

    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    def intake_data_hash(benefit_type:, category:, contests:, decision_date:, decision_text:, id:, notes:)
      identified = benefit_type.present? && category.present?
      {
        rating_issue_reference_id: (contests == "on_file_rating_issue") ? id : nil,
        rating_issue_diagnostic_code: nil,
        decision_text: decision_text,
        decision_date: decision_date,
        nonrating_issue_category: category,
        benefit_type: benefit_type,
        notes: notes,
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
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
  end
end
