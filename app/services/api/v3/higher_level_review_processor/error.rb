# frozen_string_literal: true

# This module maps error codes (originating from both the intake models and the
# HigherLevelReviewProcessor) to JSON:API-style error hashes which can be
# return to an API consumer.
# It is not intended to be used as a mixin.

module Api::V3::HigherLevelReviewProcessor::Error
  Error = Struct.new(:status, :code, :title)

  # BY_CODE is a hash of Error structs with symbol keys. Errors marked with
  # "# i" come from the intake model (otherwise the error is a validation from
  # HigherLevelReviewProcessor)

  # columns: status | code | title
  BY_CODE = [
    [403, :veteran_not_accessible, "You don't have permission to view this veteran's information"], # i
    [404, :veteran_not_found, "Veteran not found"], # i
    [409, :duplicate_intake_in_progress, "Intake in progress"], # i
    [422, :adding_legacy_issue_without_opting_in, "To add a legacy issue, legacy_opt_in_approved must be true"],
    [422, :incident_flash, "The veteran has an incident flash"], # i
    [422, :invalid_file_number, "Veteran ID not found"], # i
    [
      422,
      :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id,
      "If you specify a legacy appeal, you must specify which issue (legacy_appeal_issue_id)"
    ],
    [
      422,
      :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id,
      "If you specify a legacy appeal issue, you must specify which legacy appeal it belongs to (legacy_appeal_id)"
    ],
    [422, :request_issue_cannot_be_empty, "Request issue cannot be empty"],
    [422, :unknown_category_for_benefit_type, "Unknown category for specified benefit type"],
    [422, :veteran_has_multiple_phone_numbers, "The veteran has multiple active phone numbers"], # i
    [422, :veteran_not_modifiable, "You don't have permission to intake this veteran"], # i
    [
      422,
      :veteran_not_valid, # i
      "The veteran's profile has missing or invalid information required to create an EP"
    ],
    [500, :intake_review_failed, "The review step of processing the intake failed for an unknown reason"],
    [500, :intake_start_failed, "The start step of processing the intake failed for an unknown reason"],
    [500, :reserved_veteran_file_number, "Invalid veteran file number"] # i
  ].each_with_object({}) do |args, hash|
    hash[args[1]] = Error.new(*args)
  end.freeze

  # this is the error given when error code lookup fails. Note: :unknown_error is not in the list above
  FOR_UNKNOWN_CODE = Error.new(500, :unknown_error, "Unknown error")

  # returns the full Error for a given error code
  def self.from_error_code(code)
    BY_CODE[code.to_s.to_sym] || FOR_UNKNOWN_CODE
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
end
