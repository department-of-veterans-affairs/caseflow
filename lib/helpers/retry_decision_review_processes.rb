# frozen_string_literal: true

class RetryDecisionReviewProcesses
  class << self
    def retry
      logs = ["RetryDecisionReviewProcesses Log"]

      puts "Total error count: #{all_records.count}"
      all_records.each do |instance|
        error_field = instance.is_a?(RequestIssuesUpdate) ? :error : :establishment_error
        error = instance[error_field]
        DecisionReviewProcessJob.perform_now(instance)
        instance.reload
        # if the error field is now empty, we succeeded. we should log it
        if instance[error_field].nil? # rubocop:disable Style/Next
          log = format_log(instance, error)
          puts "\n\n\n" + log + "\n\n\n"
          logs << log
        end
      end

      logs << "No successful remediations" if logs.length == 1
      upload_logs(logs)
    end

    private

    def format_log(instance, error)
      error_title = known_error(error)
      error_title = error.split[0] if error_title.nil?

      "Remediated #{instance.class.name}: #{instance.id} #{error_title}"
    end

    def known_error(error)
      KNOWN_ERRORS.each do |error_obj|
        if error_obj.is_a?(Array)
          return error_obj.join if error_obj.all? { |err| error.include?(err) }
        elsif error.include?(error_obj)
          return error_obj
        end
      end
      nil
    end

    def all_records
      supplemental_claims + higher_level_reviews + request_issue_updates
    end

    def supplemental_claims
      SupplementalClaim.where.not(establishment_error: nil).where(establishment_canceled_at: nil)
    end

    def higher_level_reviews
      HigherLevelReview.where.not(establishment_error: nil).where(establishment_canceled_at: nil)
    end

    def request_issue_updates
      RequestIssuesUpdate.where.not(error: nil).where(canceled_at: nil)
    end

    def file_name
      "retry_decision_review_process_job-log-#{Time.zone.now}"
    end

    def folder_name
      folder = "data-remediation-output"
      (Rails.deploy_env == :prod) ? folder : "#{folder}-#{Rails.deploy_env}"
    end

    def upload_logs(logs)
      S3Service.store_file("#{folder_name}/#{file_name}", logs.join("\n"))
    end

    KNOWN_ERRORS =
      [
        "DuplicateEp",
        "duplicate key value violates unique constraint",
        "AppealRepository::AppealNotValidToClose",
        ["Appeal id ", "is not valid to reopen"],
        ["Logon ID ", "Not Found in the Benefits Gateway Service (BGS)"],
        "No record found for file number",
        "The Tuxedo service is down",
        ["Can't create a SC DTA for appeal ", "due to missing payee code"],
        "Caseflow::Error::EstablishClaimFailedInVBMS",
        "Remand reasons must be present when issue disposition is remanded",
        "DecisionDocument::NotYetSubmitted",
        "EndProductEstablishment::ContentionCreationFailed",
        "EndProductEstablishment::ContentionNotFound:",
        "EndProductEstablishment::InvalidEndProductError",
        "EndProductModifierFinder::NoAvailableModifiers",
        "KeepAliveDisconnected: Connection reset by peer",
        "Page requested by the user is unavailable, please contact system administrator.",
        "upstream connect error or disconnect/reset before headers. reset reason: connection failure",
        "No payee code",
        "No space left on device",
        "OCI8 was already closed",
        "No resources currently available in pool wbcdd_M8 to allocate to applications, please increase the size of "\
          "the pool and retry",
        "Rating::NilRatingProfileListError",
        "Error 404--Not Found",
        "status_code=408, body=stream timeout",
        "VBMS is currently unavailable",
        "Benefit Type, Payee code or EP Code is not valid.",
        "bip.icpdataservice.icp.sys.error",
        "Cannot establish claim for Veteran who does not have both a Corporate and BIRLS record. Record found: "\
          "Corporate",
        ["Tried to create an open work item for a claim (claim ID = ", ") in a non-active state"],
        "MessageException thrown in",
        "MISSING_REQUIRED_FIELD",
        ["No contention with id", " could not be found."],
        ["Transaction timed out after ", "seconds"],
        "A problem has been detected with the upload token provided.",
        "FILENUMBER does not exist within the system",
        "The System has encountered an unknown error. Please contact your administrator.",
        "The document is currently locked by another user or process.",
        "503 Service Unavailable",
        "unable to sign request without credentials set",
        "undefined method",
        "Validation failed: Address blank",
        "Validation failed: Address invalid",
        "The contention is connected to an issue in ratings and cannot be deleted",
        "Retrieving Contention list failed. System error.",
        "Unable to establish claim: Duplicate Veteran Records found on Corporate",
        "MINIMUM_LENGTH_NOT_SATISFIED",
        "Error retrieving fileNumber by provided claimId.",
        "postalCode field has invalid format",
        "ShareException thrown in",
        "Unable to retrieve Award SOJ for given Country:",
        "ORACLE ERROR when attempting to store Dependent Data",
        "Unable to establish claim: insertBenefitClaim:",
        "Unable to establish claim: GUIE99998",
        "GetIcpDetailByFileNumberCommand could not be queued for execution and fallback failed",
        "Unknown error while creating exceptions for ClaimID:",
        "INVALID_DATA_VALUE",
        "Failed to get claim by Id. claimId:",
        "Could not access remote service at",
        "Your account is locked.",
        "VBMS::InvalidCharacterError",
        "Claim modifier is invalid for given Claim EP Code.",
        "Unable to associate rated issue, rated issue does not exist",
        ["Logon ID ", "Not Found"],
        "User is not authorized",
        "ORACLE ERROR when attempting to store PTCPNT_ADDRS",
        "VBMS::XcpupError",
        "You do not have sufficient security access for this file.",
        "User Does Not Have Permission for Application"
      ].freeze
  end
end
