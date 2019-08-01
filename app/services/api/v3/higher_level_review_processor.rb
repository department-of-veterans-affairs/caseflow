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
    unknown_category_for_benefit_type: { status: 422, title: "Unknown category for benefit type" },
    unknown_contestation_type: { status: 422, title: "Cannot contest that type" },
    must_have_id_to_contest_decision_issue: { status: 422, title: "Must have id to contest decision issue" },
    must_have_id_to_contest_rating_issue: { status: 422, title: "Must have id to contest rating issue" },
    must_have_id_to_contest_legacy_issue: { status: 422, title: "Must have id to contest legacy issue" },
    notes_cannot_be_blank_when_contesting_decision_issue: {
      status: 422, title: "Notes cannot be blank when contesting decision issue"
    },
    notes_cannot_be_blank_when_contesting_rating_issue: {
      status: 422, title: "Notes cannot be blank when contesting rating issue"
    },
    notes_cannot_be_blank_when_contesting_legacy_issue: {
      status: 422, title: "Notes cannot be blank when contesting legacy issue"
    },
    either_notes_or_decision_text_must_be_present_when_contesting_other: {
      status: 422, title: "Either notes or decision text must be present when contesting other"
    }
  }.freeze

  DEFAULT_ERROR = { status: 422, code: :unknown_error, title: "Unknown error" }.freeze

  # this is the hash that the method "attributes_from_intake_data", in the request_issue model, is expecting
  INTAKE_DATA_HASH = {
    rating_issue_reference_id: nil,
    rating_issue_diagnostic_code: nil,
    decision_text: nil,
    decision_date: nil,
    nonrating_issue_category: nil,
    benefit_type: nil,
    notes: nil,
    is_unidentified: false, # false
    untimely_exemption: nil,
    untimely_exemption_notes: nil,
    ramp_claim_id: nil,
    vacols_id: nil,
    vacols_sequence_id: nil,
    contested_decision_issue_id: nil,
    ineligible_reason: nil,
    ineligible_due_to_id: nil,
    edited_description: nil,
    correction_type: nil
  }.freeze

  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

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

    included.each do |hash|
      next unless hash[:type] == "RequestIssue"

      request_issue, error = included_request_issue_to_intake_data_hash(hash)
      @errors << error if error
      @request_issues << request_issue if request_issue
    end
  end

  def errors?
    !errors.empty?
  end

  # all of the intake steps
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

  # params for the "review" step of the intake process
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

  # params for the "complete" step of the intake process
  def complete_params
    ActionController::Parameters.new request_issues: @request_issues
  end

  def self.error_from_error_code(code)
    return DEFAULT_ERROR unless code

    status_and_title = ERROR_STATUSES_AND_TITLES_BY_CODE[code.to_sym]
    return DEFAULT_ERROR unless status_and_title

    { status: status_and_title[:status], code: code, title: status_and_title[:title] }
  end

  def included_request_issue_to_intake_data_hash(request_issue)
    request_issue = request_issue[:attributes].as_json.symbolize_keys

    case request_issue[:contests]
    when "on_file_decision_issue"
      contesting_decision_to_intake_data_hash(request_issue)
    when "on_file_rating_issue"
      contesting_rating_to_intake_data_hash(request_issue)
    when "on_file_legacy_issue"
      contesting_legacy_to_intake_data_hash(request_issue)
    when "other"
      if request_issue[:category].present?
        contesting_categorized_other_to_intake_data_hash(request_issue)
      else
        contesting_uncategorized_other_to_intake_data_hash(request_issue)
      end
    else
      [nil, error_from_error_code(:unknown_contestation_type)]
    end
  end

  private

  def contesting_decision_to_intake_data_hash(request_issue)
    id, notes = request_issue.values_at :id, :notes
    # open question: where will attributes[:request_issue_ids] go?
    return [nil, error_from_error_code(:must_have_id_to_contest_decision_issue)] if id.blank?
    return [nil, error_from_error_code(:notes_cannot_be_blank_when_contesting_decision_issue)] if notes.blank?

    intake_data_hash(contested_decision_issue_id: id, notes: notes)
  end

  def contesting_rating_to_intake_data_hash(request_issue)
    id, notes = request_issue.values_at :id, :notes
    return [nil, error_from_error_code(:must_have_id_to_contest_rating_issue)] if id.blank?
    return [nil, error_from_error_code(:notes_cannot_be_blank_when_contesting_rating_issue)] if notes.blank?

    intake_data_hash(rating_issue_reference_id: id, notes: notes)
  end

  def contesting_legacy_to_intake_data_hash
    if !@legacy_opt_in_approved
      return [nil, error_from_error_code(:adding_legacy_issue_without_opting_in)]
    end

    id, notes = request_issue.values_at :id, :notes
    return [nil, error_from_error_code(:must_have_id_to_contest_legacy_issue)] if id.blank?
    return [nil, error_from_error_code(:notes_cannot_be_blank_when_contesting_legacy_issue)] if notes.blank?

    intake_data_hash(vacols_id: id, notes: notes)
  end

  def contesting_categorized_other_to_intake_data_hash(request_issue)
    category, notes, decision_text = request_issue.values_at :category, :notes, :decision_text
    return [nil, error_from_error_code(:unknown_category_for_benefit_type)] unless category.in?(
      CATEGORIES_BY_BENEFIT_TYPE[@benefit_type]
    )

    unless notes.present? || decision_text.present?
      return [
        nil,
        error_from_error_code(:either_notes_or_decision_text_must_be_present_when_contesting_other)
      ]
    end

    intake_data_hash(
      request_issue.slice(:notes, :decision_date, :decision_text).merge(nonrating_issue_category: category)
    )
  end

  def contesting_uncategorized_other_to_intake_data_hash(request_issue)
    notes, decision_text = request_issue.values_at :notes, :decision_text
    unless notes.present? || decision_text.present?
      return [
        nil, error_from_error_code(:either_notes_or_decision_text_must_be_present_when_contesting_other)
      ]
    end

    intake_data_hash(request_issue.slice(:notes, :decision_date, :decision_text).merge(is_unidentified: true))
  end

  def intake_data_hash(hash)
    [INTAKE_DATA_HASH.merge(benefit_type: @benefit_type).merge(hash), nil]
  end
end
