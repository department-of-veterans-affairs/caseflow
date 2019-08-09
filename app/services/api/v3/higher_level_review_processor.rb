# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  Error = Struct.new(:status, :code, :title)

  # ERRORS_BY_CODE is a hash of Error structs with symbol keys
  # errors marked with #i come from the intake model (otherwise the error is a validation from this class)
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
    [422, :unknown_category_for_benefit_type, "Unknown category for specified benefit type"],
    [422, :unknown_contestation_type, "Can only contest: \"on_file_(decision|rating|legacy)_issue\" or \"other\""],
    [422, :veteran_has_multiple_phone_numbers, "The veteran has multiple active phone numbers"], # i
    [422, :veteran_not_modifiable, "You don't have permission to intake this veteran"], # i
    [
      422,
      :veteran_not_valid, # i
      "The veteran's profile has missing or invalid information required to create an EP"
    ],
    [500, :reserved_veteran_file_number, "Invalid veteran file number"] # i
  ].each_with_object({}) do |args, hash|
    hash[args[1]] = Error.new(*args)
  end.freeze

  # this is the error given when error code lookup fails. Note: :unknown_error is not in the list above
  ERROR_FOR_UNKNOWN_CODE = Error.new(500, :unknown_error, "Unknown error")

  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  attr_reader :errors, :intake, :review_params, :complete_params

  # Instance variables are set in the initialize* methods and nowhere else.
  # That is, the internal state of a processor is set here and is not changed (this is NOT including
  # the internal states of intake and intake.detail). This is true even for the @errors array
  # --errors after this step are exceptions thrown by the models or in the transaction.
  def initialize(params, user)
    @errors = []
    initialize_intake(params, user)
    initialize_review_params(params)
    initialize_complete_params(params)
  end

  def errors?
    errors.any?
  end

  def higher_level_review
    intake.detail&.reload
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

  class << self
    # returns the full Error for a given error code
    def error_from_error_code(code)
      ERRORS_BY_CODE[code.to_s.to_sym] || ERROR_FOR_UNKNOWN_CODE
    end

    # returns array of claimant_participant_id and claimant_payee_code
    def claimant_from_params(params)
      claimant = params[:data][:relationships][:claimant]
      return [nil, nil] unless claimant

      data = claimant[:data]
      [data[:id], data[:meta][:payeeCode]]
    end

    def veteran_file_number_from_params(params)
      params[:data][:relationships][:veteran][:data][:id]
    end

    def review_params_from_params(params)
      attributes = params[:data][:attributes]
      claimant_participant_id, claimant_payee_code = claimant_from_params(params)
      ActionController::Parameters.new(
        informal_conference: attributes[:informalConference],
        same_office: attributes[:sameOffice],
        benefit_type: attributes[:benefitType],
        receipt_date: attributes[:receiptDate],
        claimant: claimant_participant_id,
        veteran_is_not_claimant: claimant_participant_id.present? || claimant_payee_code.present?,
        payee_code: claimant_payee_code,
        legacy_opt_in_approved: attributes[:legacyOptInApproved]
      )
    end

    def complete_params_and_errors_from_params(params)
      legacy_opt_in_approved, benefit_type = review_params_from_params(params).values_at(
        :legacy_opt_in_approved, :benefit_type
      )

      json_api_request_issues, errors = (
        if legacy_opt_in_approved
          [included_request_issues(params), []]
        else
          included_request_issues_and_errors_for_each_legacy_issue(params)
        end
      )

      intake_data_hash_request_issues = []
      json_api_request_issues.each do |issue|
        value = json_api_request_issue_attributes_to_error_or_intake_data_hash(issue[:attributes], benefit_type)

        if value.is_a?(Error)
          errors << value
        else
          intake_data_hash_request_issues << { benefit_type: benefit_type }.merge(value)
        end
      end

      [ActionController::Parameters.new(request_issues: intake_data_hash_request_issues), errors]
    end

    def included_request_issues(params)
      params[:included].select { |included_item| included_item[:type] == "RequestIssue" }
    end

    def included_request_issues_and_errors_for_each_legacy_issue(params)
      request_issues = []
      legacy_errors = []

      included_request_issues(params).each do |request_issue|
        if request_issue[:attributes][:contests] == "on_file_legacy_issue"
          legacy_errors << error_from_error_code(:adding_legacy_issue_without_opting_in)
        else
          request_issues << request_issue
        end
      end

      [request_issues, legacy_errors]
    end

    # either converts a JSON:API-shaped request issue to an "intake data hash"
    # --the shape of hash expected by the "attributes_from_intake_data" method (request_issue model)--
    # or, if unsuccessful, returns an error
    def json_api_request_issue_attributes_to_error_or_intake_data_hash(attributes, benefit_type)
      case attributes[:contests]
      when "on_file_decision_issue"
        contesting_on_file_to_intake_data_hash(attributes, :decision)
      when "on_file_rating_issue"
        contesting_on_file_to_intake_data_hash(attributes, :rating)
      when "on_file_legacy_issue"
        contesting_on_file_to_intake_data_hash(attributes, :legacy)
      when "other"
        contesting_other_to_intake_data_hash(attributes, benefit_type)
      else
        error_from_error_code(:unknown_contestation_type)
      end
    end

    def contesting_other_to_intake_data_hash(attributes, benefit_type)
      if attributes[:category].nil?
        contesting_other_to_intake_data_hash_for_category(attributes, nil)
      elsif attributes[:category].in?(CATEGORIES_BY_BENEFIT_TYPE[benefit_type])
        contesting_other_to_intake_data_hash_for_category(attributes, attributes[:category])
      else
        error_from_error_code(:unknown_category_for_benefit_type)
      end
    end

    def blank_id_error_for_contest_type(type)
      "#{type}_issue_id_cannot_be_blank"
    end

    def blank_notes_error_for_contest_type(type)
      "notes_cannot_be_blank_when_contesting_#{type}"
    end

    INTAKE_DATA_HASH_ID_KEY_BY_CONTEST_TYPE = {
      decision: :contested_decision_issue_id,
      rating: :rating_issue_reference_id,
      legacy: :vacols_id
    }.freeze

    def contesting_on_file_to_intake_data_hash(request_issue, contest_type)
      id, notes = request_issue.values_at(:id, :notes)
      # open question: where will attributes[:request_issue_ids] go?

      return error_from_error_code(blank_id_error_for_contest_type(contest_type)) if id.blank?
      return error_from_error_code(blank_notes_error_for_contest_type(contest_type)) if notes.blank?

      {
        is_unidentified: false,
        INTAKE_DATA_HASH_ID_KEY_BY_CONTEST_TYPE[contest_type] => id,
        notes: notes
      }
    end

    def contesting_other_to_intake_data_hash_for_category(request_issue, category)
      notes, decision_date, decision_text = request_issue.values_at(:notes, :decision_date, :decision_text)

      return error_from_error_code(:must_have_text_to_contest_other) if notes.blank? && decision_text.blank?

      {
        is_unidentified: category.blank?,
        nonrating_issue_category: category,
        notes: notes,
        decision_date: decision_date,
        decision_text: decision_text
      }
    end
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

  private

  def initialize_intake(params, user)
    @intake = Intake.build(
      user: user,
      veteran_file_number: self.class.veteran_file_number_from_params(params),
      form_type: "higher_level_review"
    )
    @errors << self.class.error_from_error_code(intake.error_code) if intake.error_code
  end

  def initialize_review_params(params)
    @review_params = self.class.review_params_from_params(params)
  end

  def initialize_complete_params(params)
    @complete_params, errors = self.class.complete_params_and_errors_from_params(params)
    @errors += errors
  end

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
    intake.complete!(complete_params)
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
end
