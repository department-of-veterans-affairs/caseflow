# frozen_string_literal: true

# rubocop:disable Layout/LineLength
class StuckJobsReporter
  ASYNC_CLASSES = [
    SupplementalClaim,
    HigherLevelReview,
    # RequestIssue,
    RequestIssuesUpdate,
    DecisionDocument,
    BoardGrantEffectuation
  ].freeze

  SNIPPETS = [
    "DuplicateEp",
    "VBMS::EmptyContentionTitle.",
    "index_request_issues_on_contention_reference_id",
    "VBMS::UnknownUser",
    "Caseflow::Error::EstablishClaimFailedInVBMS",
    "VBMS::VeteranAddressError",
    "VBMS::IncidentFlash",
    "VBMS::BadPostalCode",
    "VBMS::XcpupError",
    "VBMS::MissingData",
    "TypeError: no implicit conversion of Symbol into Integer",
    "VBMS::DuplicateVeteranRecords",
    "EndProductEstablishment::ContentionCreationFailed",
    "VBMS::VeteranInfoNotRetrieved",
    "DTA SC creation failed",
    "Caseflow::Error::RemandReasonRepositoryError",
    "AppealRepository::AppealNotValidToClose",
    "Benefit Type, Payee code or EP Code is not valid",
    "EndProductModifierFinder::NoAvailableModifiers",
    "EndProductEstablishment::ContentionNotFound",
    "VBMSError::CannotDeleteContention",
    "VBMS::CannotDeleteContention",
    "VBMS::DownForMaintenance",
    "Could not access remote service at",
    "FILENUMBER does not exist within the system.",
    "Can't create a SC DTA for",
    "This update is being elevated for additional review due to an Incident Flash",
    "Maintenance - VBMS",
    "Rating::BackfilledRatingError",
    "GetIcpDetailByFileNumberCommand could not be queued for execution and fallback failed.",
    "Cannot establish claim for Veteran who does not have both a Corporate and BIRLS record.",
    "The establishClaim service endpoint is missing required data: participantPersonId does not have an address.",
    "WssVerification Exception - Security Verification Exception",
    "Claim not established. Unable to retrieve Veteran information.",
    "Business Errors",
    "This transaction could not be completed due to a database error.",
    "System has encountered an unknown error.",
    "Rating::NilRatingProfileListError",
    "VBMS is currently unavailable due to maintenance",
    "VbmsWSException: WssVerification Exception - Security Verification Exception",
    "A problem has been detected with the upload token provided",
    "Unable to determine validity of veteran using identifier: FILENUMBER",
    "Claim creation failed. System error",
    "A null pointer exception has occurred",
    "Claim not established. System error with BGS.",
    "Contention creation failed. System error",
    "The data value of the ClaimDateDt within the claimToEstablish did not satisfy the following condition: The ClaimDateDt value must be a valid date for a claim",
    "The establishClaim service endpoint is missing required data: participantPersonId does not have an address",
    "Removing Contention failed. System error",
    "This is a Sensitive Record and you do not have high enough access to update it",
    "Claim modifier is invalid for given Claim EP Code",
    "Retrieving Contention list failed. System error",
    "Page requested by the user is unavailable, please contact system administrator.",
    "ActiveRecord::RecordNotUnique",
    "BGS::ShareError",
    "upstream connect error or disconnect/reset before headers",
    "PromulgatedRating::BackfilledRatingError",
    "TUX-20306 - An unexpected error was encountered",
    "AppealDTAPayeeCodeError"
  ].freeze

  class << self
    def run
      RequestStore[:current_user] ||= User.system_user

      CSV.generate do |csv|
        all_jobs = ASYNC_CLASSES.map { |klass| klass.with_error.where(klass.canceled_at_column => nil) }.flatten
        all_jobs.map do |job|
          csv << generate_row(job)
        end
      end
    end

    def generate_row(job)
      error = job[job.class.error_column]
      error_category = SNIPPETS.find { |snippet| error.match?(snippet) }
      [
        job.class.name,
        job.id,
        job.veteran&.id,
        job[job.class.submitted_at_column].to_s,
        job[job.class.processed_at_column].to_s,
        error_category
      ]
    end
  end
end
# rubocop:enable Layout/LineLength
