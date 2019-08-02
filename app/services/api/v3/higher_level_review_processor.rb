# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  Error = Struct.new(:status, :code, :title)

  def self.code_from_title(title)
    return nil if title.blank?

    title = title.to_s.split(" ").join("_").downcase.gsub(/[^0-9a-z_]/i, "")
    title.blank? ? nil : title.to_sym
  end

  def self.title_from_code(code)
    return nil if code.blank?

    code.to_s.split("_").join(" ").capitalize
  end

  # creates a hash with this shape:
  # {
  #   veteran_not_found: <struct Error status=404, code=:veteran_not_found, title="Veteran not found">,
  #   invalid_file_number: <struct Error status=422, code=:invalid_file_number, title="Veteran ID not found">,
  #   incident_flash: <struct Error status=422, code=:incident_flash, title="The veteran has an incident flash">,
  #   ...
  # }
  #
  # if a code is left out, the title is turned into a code (downcase, underscores, non-alphanumeric chars removed)
  ERRORS_BY_CODE = [
    [403, :veteran_not_accessible, "You don't have permission to view this veteran's information"],
    [404, :veteran_not_found, "Veteran not found"],
    [409, :duplicate_intake_in_progress, "Intake In progress"],
    [422, :adding_legacy_issue_without_opting_in, "Adding legacy issue without opting in"],
    [422, :attributes_must_be_object, "Attributes must be object"]
    [422, :either_notes_or_decision_text_must_be_present_when_contesting_other, "Either notes or decision text must be present when contesting other"
    [422, :incident_flash, "The veteran has an incident flash"],
    [422, :intake_review_failed, "Intake review failed"],
    [422, :intake_start_failed, "Intake start failed"],
    [422, :invalid_file_number, "Veteran ID not found"],
    [422, :must_have_id_to_contest_decision_issue, "Must have id to contest decision issue"],
    [422, :must_have_id_to_contest_legacy_issue, "Must have id to contest legacy issue"],
    [422, :must_have_id_to_contest_rating_issue, "Must have id to contest rating issue"],
    [422, :notes_cannot_be_blank_when_contesting_decision_issue, "Notes cannot be blank when contesting decision issue"],
    [422, :notes_cannot_be_blank_when_contesting_legacy_issue, "Notes cannot be blank when contesting legacy issue"],
    [422, :notes_cannot_be_blank_when_contesting_rating_issue, "Notes cannot be blank when contesting rating issue"],
    [422, :reserved_veteran_file_number, "Invalid veteran file number"],
    [422, :unknown_category_for_benefit_type, "Unknown category for benefit type"],
    [422, :unknown_contestation_type, "Cannot contest that type"],
    [422, :veteran_has_multiple_phone_numbers, "The veteran has multiple active phone numbers"],
    [422, :veteran_not_modifiable, "You don't have permission to intake this veteran"],
    [422, :veteran_not_valid, "The veteran's profile has missing or invalid information required to create an EP."],
    ],
  ].each_with_object({}) do |(status, errors), acc|
    errors.each do |(code, title)|
      title ||= title_from_code(code)
      acc[code] = Error.new(status, code, title)
    end
  end.freeze

  ERROR_FOR_UNKNOWN_CODE = Error.new(422, :unknown_error, "Unknown error")

  def error_from_error_code(code)
    ERRORS_BY_CODE[code.to_s.to_sym] || ERROR_FOR_UNKNOWN_CODE
  end

  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  attr_reader :intake, :errors

  def initialize(params, user)
    @errors = []
    @receipt_date, @informal_conference, @same_office, @legacy_opt_in_approved, @benefit_type = attributes(params)
    veteran_file_number, @claimant_participant_id, @claimant_payee_code = veteran_and_claimant(params)
    @intake = Intake.build(user: user, veteran_file_number: veteran_file_number, form_type: "higher_level_review")
    @errors << error_from_error_code(intake.error_code) if intake.error_code
    @request_issues = []
    params[:included].each do |included_item|
      next unless included_item[:type] == "RequestIssue"

      value = included_request_issue_to_intake_data_hash(included_item)
      (value.is_a?(self.class::Error) ? @errors : @request_issues) << value
    end
  end

  def errors?
    !errors.empty?
  end

  class StartError < StandardError
    def initialize(intake)
      @intake = intake
      super("intake.start! did not throw an exception, but did return a falsey value")
    end

    def error_code
      @intake.error_code || :intake_start_failed
    end
  end

  class ReviewError < StandardError
    def initialize(intake)
      @intake = intake
      msg = "intake.review!(review_params) did not throw an exception, but did return a falsey value"
      review_errors = @intake.detail.errors
      msg = ["#{msg}:", *review_errors.full_messages].join("\n") if review_errors.present?
      super(msg)
    end

    def error_code
      @intake.error_code || :intake_review_failed
    end
  end

  # this method performs all of the intake steps which write to DBs
  # both start and review can signal a failure by either throwing an exception OR returning a falsey value
  def start_review_complete!
    transaction do
      fail StartError, intake unless intake.start!
      fail ReviewError, intake unless intake.review!(review_params)

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

  # initialize helper
  def attributes(params)
    params[:data][:attributes].values_at(
      :receiptDate, :informalConference, :sameOffice, :legacyOptInApproved, :benefitType
    )
  end

  # initialize helper
  def veteran_and_claimant(params)
    relationships = params[:data][:relationships]
    claimant = relationships[:claimant]
    [
      relationships[:veteran][:data][:id],
      *(claimant ? [claimant.dig(:data, :id), claimant.dig(:data, :meta, :payeeCode)] : [])
    ]
  end

  # initialize helper
  def included_request_issue_to_intake_data_hash(request_issue)
    request_issue = request_issue[:attributes]

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
      error_from_error_code(:unknown_contestation_type)
    end
  end

  private

  # the helper methods below create hashes in the shape that the method
  # "attributes_from_intake_data" (request_issue model) is expecting
  #
  # possible values:
  #
  # {
  #   rating_issue_reference_id: nil,
  #   rating_issue_diagnostic_code: nil,
  #   decision_text: nil,
  #   decision_date: nil,
  #   nonrating_issue_category: nil,
  #   benefit_type: nil,
  #   notes: nil,
  #   is_unidentified: nil,
  #   untimely_exemption: nil,
  #   untimely_exemption_notes: nil,
  #   ramp_claim_id: nil,
  #   vacols_id: nil,
  #   vacols_sequence_id: nil,
  #   contested_decision_issue_id: nil,
  #   ineligible_reason: nil,
  #   ineligible_due_to_id: nil,
  #   edited_description: nil,
  #   correction_type: nil
  # }

  def contesting_decision_to_intake_data_hash(request_issue)
    request_issue = request_issue.permit(:id, :notes)
    id, notes = request_issue.values_at :id, :notes
    # open question: where will attributes[:request_issue_ids] go?
    return error_from_error_code(:must_have_id_to_contest_decision_issue) if id.blank?
    return error_from_error_code(:notes_cannot_be_blank_when_contesting_decision_issue) if notes.blank?

    intake_data_hash(contested_decision_issue_id: id, notes: notes)
  end

  def contesting_rating_to_intake_data_hash(request_issue)
    request_issue = request_issue.permit(:id, :notes)
    id, notes = request_issue.values_at :id, :notes

    return error_from_error_code(:must_have_id_to_contest_rating_issue) if id.blank?
    return error_from_error_code(:notes_cannot_be_blank_when_contesting_rating_issue) if notes.blank?

    intake_data_hash(rating_issue_reference_id: id, notes: notes)
  end

  def contesting_legacy_to_intake_data_hash(request_issue)
    if !@legacy_opt_in_approved
      return error_from_error_code(:adding_legacy_issue_without_opting_in)
    end

    request_issue = request_issue.permit(:id, :notes)
    id, notes = request_issue.values_at :id, :notes

    return error_from_error_code(:must_have_id_to_contest_legacy_issue) if id.blank?
    return error_from_error_code(:notes_cannot_be_blank_when_contesting_legacy_issue) if notes.blank?

    intake_data_hash(vacols_id: id, notes: notes)
  end

  def contesting_categorized_other_to_intake_data_hash(request_issue)
    request_issue = request_issue.permit(:category, :notes, :decision_date, :decision_text)
    category, notes, decision_text = request_issue.values_at :category, :notes, :decision_text

    return error_from_error_code(:unknown_category_for_benefit_type) unless category.in?(
      CATEGORIES_BY_BENEFIT_TYPE[@benefit_type]
    )

    unless notes.present? || decision_text.present?
      return error_from_error_code(:either_notes_or_decision_text_must_be_present_when_contesting_other)
    end

    intake_data_hash(
      request_issue.slice(:notes, :decision_date, :decision_text).merge(nonrating_issue_category: category)
    )
  end

  def contesting_uncategorized_other_to_intake_data_hash(request_issue)
    request_issue = request_issue.permit(:notes, :decision_date, :decision_text)
    notes, decision_text = request_issue.values_at :notes, :decision_text

    unless notes.present? || decision_text.present?
      return error_from_error_code(:either_notes_or_decision_text_must_be_present_when_contesting_other)
    end

    intake_data_hash(request_issue.slice(:notes, :decision_date, :decision_text).merge(is_unidentified: true))
  end

  def intake_data_hash(hash)
    { is_unidentified: false, benefit_type: @benefit_type }.merge(hash)
  end
end
