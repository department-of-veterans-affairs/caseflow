# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  Error = Struct.new(:status, :code, :title)

  # ERRORS_BY_CODE becomes a hash of Error structs with symbol keys
  # errors marked with
  #   #i come from the intake model
  #   #p are returned by validations in this class
  # columns: status | code | title
  ERRORS_BY_CODE = [
    [403, :veteran_not_accessible, "You don't have permission to view this veteran's information"], # i
    [404, :veteran_not_found, "Veteran not found"], # i
    [409, :duplicate_intake_in_progress, "Intake in progress"], # i
    [422, :adding_legacy_issue_without_opting_in, "To add a legacy issue, legacy_opt_in_approved must be true"],
    [422, :decision_issue_id_cannot_be_blank, "Must specify a decision issue ID to contest a decision issue"],
    [422, :incident_flash, "The veteran has an incident flash"], # i
    [422, :intake_review_failed, "The review step of processing the intake failed"],
    [422, :intake_start_failed, "The start step of processing the intake failed"],
    [422, :invalid_file_number, "Veteran ID not found"], # i
    [422, :legacy_issue_id_cannot_be_blank, "Must specify a legacy issue ID to contest a legacy issue"],
    [422, :must_have_text_to_contest_other, "notes or decision_text must be non-blank when contesting \"other\""],
    [422, :notes_cannot_be_blank_when_contesting_decision, "Notes cannot be blank when contesting a decision"],
    [422, :notes_cannot_be_blank_when_contesting_legacy, "Notes cannot be blank when contesting a legacy issue"],
    [422, :notes_cannot_be_blank_when_contesting_rating, "Notes cannot be blank when contesting a rating"],
    [422, :rating_issue_id_cannot_be_blank, "Must specify a rating issue ID to contest a rating issue"],
    [422, :reserved_veteran_file_number, "Invalid veteran file number"], # i
    [422, :unknown_category_for_benefit_type, "Unknown category for specified benefit type"],
    [422, :unknown_contestation_type, "Can only contest: \"on_file_(decision|rating|legacy)_issue\" or \"other\""],
    [422, :veteran_has_multiple_phone_numbers, "The veteran has multiple active phone numbers"], # i
    [422, :veteran_not_modifiable, "You don't have permission to intake this veteran"], # i
    [422, :veteran_not_valid, "The veteran's profile has missing or invalid information required to create an EP"]
  ].each_with_object({}) do |args, hash|
    hash[args[1]] = Error.new(*args)
  end.freeze

  # this is the error given when error code lookup fails.  :unknown_error is not in the list above
  ERROR_FOR_UNKNOWN_CODE = Error.new(422, :unknown_error, "Unknown error")

  # returns the full Error for a given error code
  def self.error_from_error_code(code)
    ERRORS_BY_CODE[code.to_s.to_sym] || ERROR_FOR_UNKNOWN_CODE
  end

  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  attr_reader :intake, :errors

  # Instance variables are set in initialize and nowhere else. Besides what the models do to intake and
  # intake.detail, the internal state of a processor is set here and is not changed. This is true even for
  # the @errors array --errors after this step are exceptions thrown by the models or in the transaction.
  def initialize(params, user)
    @errors = []
    @receipt_date, @informal_conference, @same_office, @legacy_opt_in_approved, @benefit_type = attributes(params)
    veteran_file_number, @claimant_participant_id, @claimant_payee_code = veteran_and_claimant(params)
    @intake = Intake.build(user: user, veteran_file_number: veteran_file_number, form_type: "higher_level_review")
    @errors << self.class.error_from_error_code(intake.error_code) if intake.error_code
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
      review_errors = @intake&.detail&.errors
      msg = ["#{msg}:", *review_errors.full_messages].join("\n") if review_errors.present?
      super(msg)
    end

    def error_code
      @intake.error_code || :intake_review_failed
    end
  end

  # this method performs all of the intake steps which write to DBs
  # this method fails by exception. some exceptions will have an error_code method
  def start_review_complete!
    ActiveRecord::Base.transaction do
      start!
      review!
      complete!
    end
  end

  def higher_level_review
    intake.detail&.reload
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
    ActionController::Parameters.new(request_issues: @request_issues)
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
      self.class.error_from_error_code(:unknown_contestation_type)
    end
  end

  private

  # both intake.start! and intake.review! can signal a failure by either
  # throwing an exception OR returning a falsey value. consequently, false
  # returns are turned into execptions (with error codes) to rollback the
  # transaction
  def start!
    fail(StartError, intake) unless intake.start!
  end

  def review!
    fail(ReviewError, intake) unless intake.review!(review_params)
  end

  def complete!
    intake.complete! complete_params
  end

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
    id, notes = request_issue.values_at(:id, :notes)
    # open question: where will attributes[:request_issue_ids] go?

    return self.class.error_from_error_code(:decision_issue_id_cannot_be_blank) if id.blank?
    return self.class.error_from_error_code(:notes_cannot_be_blank_when_contesting_decision) if notes.blank?

    intake_data_hash(contested_decision_issue_id: id, notes: notes)
  end

  def contesting_rating_to_intake_data_hash(request_issue)
    id, notes = request_issue.values_at(:id, :notes)

    return self.class.error_from_error_code(:rating_issue_id_cannot_be_blank) if id.blank?
    return self.class.error_from_error_code(:notes_cannot_be_blank_when_contesting_rating) if notes.blank?

    intake_data_hash(rating_issue_reference_id: id, notes: notes)
  end

  def contesting_legacy_to_intake_data_hash(request_issue)
    if !@legacy_opt_in_approved
      return self.class.error_from_error_code(:adding_legacy_issue_without_opting_in)
    end

    id, notes = request_issue.values_at(:id, :notes)
    return self.class.error_from_error_code(:legacy_issue_id_cannot_be_blank) if id.blank?
    return self.class.error_from_error_code(:notes_cannot_be_blank_when_contesting_legacy) if notes.blank?

    intake_data_hash(vacols_id: id, notes: notes)
  end

  def contesting_categorized_other_to_intake_data_hash(request_issue)
    category, notes, decision_date, decision_text = request_issue.values_at(
      :category, :notes, :decision_date, :decision_text
    )

    unless category.in?(CATEGORIES_BY_BENEFIT_TYPE[@benefit_type])
      return self.class.error_from_error_code(:unknown_category_for_benefit_type)
    end

    unless notes.present? || decision_text.present?
      return self.class.error_from_error_code(:must_have_text_to_contest_other)
    end

    intake_data_hash(
      nonrating_issue_category: category,
      notes: notes,
      decision_date: decision_date,
      decision_text: decision_text
    )
  end

  def contesting_uncategorized_other_to_intake_data_hash(request_issue)
    notes, decision_date, decision_text = request_issue.values_at(:notes, :decision_date, :decision_text)

    return self.class.error_from_error_code(:must_have_text_to_contest_other) unless
      notes.present? || decision_text.present?

    intake_data_hash(
      is_unidentified: true,
      notes: notes,
      decision_date: decision_date,
      decision_text: decision_text
    )
  end

  def intake_data_hash(hash)
    { is_unidentified: false, benefit_type: @benefit_type }.merge(hash)
  end
end
