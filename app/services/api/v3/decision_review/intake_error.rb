# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeError
  class << self
    # An error_code is a symbol, a symbol derived from a string, or the symbol
    # derived from an object's error_code method (which must return a symbol
    # or string). A /valid/ error_code is a symbol in the KNOWN_ERRORS array.
    # :reek:ManualDispatch:
    def error_code(obj)
      case obj
      when Symbol
        obj
      when String
        obj.to_sym
      else
        obj.respond_to?(:error_code) ? error_code(obj.error_code) : nil
      end
    end

    def find_first_error_code(array)
      array.each do |obj|
        code = error_code(obj)
        return code if code
      end

      nil
    end

    # An alternative to new.
    # Given an array, it uses the first error_code found
    def from_first_error_code_found(array)
      new find_first_error_code(array)
    end
  end

  attr_reader :status, :code, :title

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
    [422, :invalid_file_number, "Veteran ID not found"], # i
    [422, :request_issue_cannot_be_empty, "A request issue cannot be empty"],
    [
      422,
      :request_issue_category_invalid_for_benefit_type,
      "Request issue category for specified benefit type"
    ],
    [
      422,
      :request_issue_legacyAppealId_is_blank_when_legacyAppealIssueId_is_present,
      [
        "If you specify a legacy appeal issue, you must specify",
        "which legacy appeal it belongs to (legacy_appeal_id)"
      ].join(" ")
    ],
    [
      422,
      :request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present,
      [
        "If you specify a legacy appeal, you must specify",
        "which issue (legacy_appeal_issue_id) of that appeal"
      ].join(" ")
    ],
    [
      422,
      :request_issue_legacy_not_opted_in,
      "To add a legacy issue, legacyOptInApproved must be true"
    ],
    [422, :request_issue_malformed, "Malformed RequestIssue"],
    [
      422,
      :request_issue_must_have_at_least_one_ID_field,
      [
        "A request issue must have at least one of the following:",
        "decisionIssueId,",
        "ratingIssueId,",
        "legacyAppealId,",
        "legacyAppealIssueId"
      ].join(" ")
    ],
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

  def initialize(obj = nil)
    @status, @code, @title = (KNOWN_ERRORS_BY_CODE[self.class.error_code(obj)] || UNKNOWN_ERROR)
  end

  def to_h
    { status: status, code: code, title: title }
  end
end
