# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeError
  class << self
    # A valid error code is a symbol listed in the KNOWN_ERRORS array.
    # This method attempts to extract a symbol from an object's error_code
    # method, or, if that fails, attempts to convert the object itself to a
    # symbol. The symbol may or may not be a valid error code. Fails with nil.
    def potential_error_code(val)
      error_code = val.respond_to?(:error_code) ? val.error_code : val

      error_code.try(:to_sym) || error_code
    end

    def find_first_potential_error_code_that_is_a_symbol(array)
      array.map { |val| potential_error_code(val) }.find { |error_code| error_code.is_a? Symbol }
    end

    # An alternative to new.
    # Given an array, it uses the first potential error_code found.
    # Note: if you supplied this array as your argument:
    #   [:a_symbol_that_isnt_a_valid_error_code, :veteran_not_found]
    # A new IntakeError would be created using :a_symbol_that_isnt_a_valid_error_code
    # which would be UNKNOWN_ERROR.
    def from_first_potential_error_code_found(array)
      new(
        find_first_potential_error_code_that_is_a_symbol(array) ||
          array.find { |val| !val.nil? }
      )
    end
  end

  # columns: status | code | title
  KNOWN_ERRORS = [
    [400, :malformed_request, "Malformed request"],
    [
      403,
      :veteran_not_accessible,
      "You don't have permission to view this veteran's information"
    ], # i
    [404, :veteran_not_found, "Veteran not found"], # i
    [409, :duplicate_intake_in_progress, "Intake in progress"], # i
    [422, :incident_flash, "The veteran has an incident flash"], # i
    [
      422,
      :invalid_benefit_type,
      "That Line of Business (benefit type) is either invalid or not currently supported"
    ],
    [422, :invalid_file_number, "Veteran ID not found"], # i
    [422, :malformed_contestable_issues, "Malformed ContestableIssues"],
    [
      422,
      :contestable_issue_params_must_have_ids,
      "A contestable issue must have at least one of the following: decisionIssueId," \
        " ratingIssueId, ratingDecisionIssueId"
    ],
    [422, :couldnt_find_contestable_issue, "Couldn't find ContestableIssue"],
    [
      422,
      :veteran_has_multiple_phone_numbers,
      "The veteran has multiple active phone numbers"
    ], # i
    [
      422,
      :veteran_not_modifiable,
      "You don't have permission to intake this veteran"
    ], # i
    [
      422,
      :veteran_not_valid,
      "The veteran's profile has missing or invalid information required to create an EP"
    ], # i
    [
      500,
      :intake_review_failed,
      "The review step of processing the intake failed for an unknown reason"
    ],
    [
      500,
      :intake_start_failed,
      "The start step of processing the intake failed for an unknown reason"
    ],
    [500, :reserved_veteran_file_number, "Invalid veteran file number"] # i
  ].freeze

  UNKNOWN_ERROR = [500, :unknown_error, "Unknown error"].freeze

  KNOWN_ERRORS_BY_CODE = KNOWN_ERRORS.each_with_object({}) { |array, hash| hash[array.second] = array }

  attr_reader :status, :code, :title, :detail, :passed_in_object, :error_code

  def initialize(obj = nil, detail = nil)
    @error_code = self.class.potential_error_code(obj)
    @status, @code, @title = KNOWN_ERRORS_BY_CODE[@error_code] || UNKNOWN_ERROR
    @detail = detail
    @passed_in_object = obj
  end

  def to_h
    { status: status, code: code, title: title }.merge(detail_hash)
  end

  private

  def detail_hash
    @detail.nil? ? {} : { detail: @detail }
  end
end
