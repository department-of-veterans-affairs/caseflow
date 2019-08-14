# frozen_string_literal: true

class Api::V3::HigherLevelReviewProcessor
  # tweaked for happy path
  CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES.slice("compensation")
  # CATEGORIES_BY_BENEFIT_TYPE = Constants::ISSUE_CATEGORIES

  attr_reader :errors, :intake, :review_params, :complete_params

  # Instance variables are set in the initialize* methods and nowhere else.
  # That is, the internal state of a processor is set here and is not changed (this is NOT including
  # the internal states of intake and intake.detail). This is true even for the @errors array
  # --errors after this step are exceptions thrown during the transaction.
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

  # this method performs all of the intake steps which write to DBs.
  # this method fails by exception. some exceptions will have an error_code method
  def start_review_complete!
    ActiveRecord::Base.transaction do
      start!
      review!
      complete!
    end
  end

  class << self
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
        # tweaked for happy path: legacy_opt_in_approved always true (regardless of input) for happy path
        legacy_opt_in_approved: true
        # legacy_opt_in_approved: attributes[:legacyOptInApproved]
      )
    end

    # pulls :included, :benefit_type, and :legacy_opt_in_approved from params
    def included_objects_benefit_type_legacy_opt_in_approved(params)
      [params[:included], review_params_from_params(params).values_at(:benefit_type, :legacy_opt_in_approved)]
    end

    # returns params for the "complete" step for the IntakesController and errors
    def complete_params_and_errors(included_objects, benefit_type, legacy_opt_in_approved)
      request_issues = [] # an array of request issue params objects
      errors = []
      included_objects.each do |obj|
        next unless obj[:type] == "RequestIssue"

        request_issue_params = RequestIssueParams::ApiShape.to_intakes_controller_shape(obj, benefit_type)
        error = RequestIssueParams::IntakesControllerShape.validate(request_issue_params, legacy_opt_in_approved)
        if error
          errors << error
        else
          request_issues << request_issue_params
        end
      end
      [ActionController::Parameters.new(request_issues: request_issues), errors]
    end
  end

  private

  def initialize_intake(params, user)
    @intake = Intake.build(
      user: user,
      veteran_file_number: self.class.veteran_file_number_from_params(params),
      form_type: "higher_level_review"
    )
    @errors << Error.from_error_code(intake.error_code) if intake.error_code
  end

  def initialize_review_params(params)
    @review_params = self.class.review_params_from_params(params)
  end

  def initialize_complete_params(_params)
    @complete_params, errors = self.class.complete_params_and_errors_from_params(
      *included_objects_benefit_type_legacy_opt_in_approved
    )
    @errors += errors
  end

  # both intake.start! and intake.review! can signal a failure by either
  # throwing an exception OR returning a falsey value. consequently, false
  # returns are turned into execptions (with error codes) to rollback the
  # transaction
  def start!
    fail(Error::StartError, intake) unless intake.start!
  end

  def review!
    fail(Error::ReviewError, intake) unless intake.review!(review_params)
  end

  def complete!
    intake.complete!(complete_params)
  end
end
