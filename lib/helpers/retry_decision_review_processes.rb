# frozen_string_literal: true

class RetryDecisionReviewProcesses
  def initialize(report_service: nil)
    @report_service = report_service
  end

  # :reek:FeatureEnvy
  def retry # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize
    attempted_logs = ["RetryDecisionReviewProcesses Attempt Log"]
    success_logs = ["RetryDecisionReviewProcesses Success Log"]
    new_error_logs = ["RetryDecisionReviewProcesses New Error Log"]
    all_records.each do |instance|
      is_riu = instance.is_a?(RequestIssuesUpdate)
      error_field = is_riu ? :error : :establishment_error
      error = instance[error_field]
      attempted_logs << format_log(instance, error)
      begin
        if is_riu
          instance.perform!
        else
          DecisionReviewProcessJob.perform_now(instance)
        end
      rescue StandardError => error
        @report_service&.append_error(instance.class.name, instance.id, error)
        next
      end

      instance.reload
      # if the error field is now empty, we succeeded. we should log it
      if instance[error_field].nil?
        log = format_log(instance, error)
        success_logs << log
      # if the error field has changed, let's log that too
      elsif instance[error_field] != error
        log = format_log(instance, instance[error_field])
        new_error_logs << log
      end
    end

    success_logs << "No successful remediations" if success_logs.length == 1
    new_error_logs << "No new errors" if new_error_logs.length == 1
    upload_logs(attempted_logs, "attempted")
    upload_logs(success_logs, "success")
    upload_logs(new_error_logs, "new_errors")
  end

  def all_records
    supplemental_claims + higher_level_reviews + request_issue_updates
  end

  private

  # :reek:FeatureEnvy
  def format_log(instance, error)
    error_title = known_error(error)
    error_title = error.split[0] if error_title.nil?

    "#{instance.class.name}: #{instance.id} #{error_title}"
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

  def supplemental_claims
    SupplementalClaim.where.not(establishment_error: nil).where(establishment_canceled_at: nil)
  end

  def higher_level_reviews
    HigherLevelReview.where.not(establishment_error: nil).where(establishment_canceled_at: nil)
  end

  def request_issue_updates
    RequestIssuesUpdate.where.not(error: nil).where(canceled_at: nil)
  end

  def file_name(type)
    "retry_decision_review_process_job-logs/retry_decision_review_process_job_#{type}-log-#{Time.zone.now}"
  end

  def folder_name
    folder = "data-remediation-output"
    (Rails.deploy_env == :prod) ? folder : "#{folder}-#{Rails.deploy_env}"
  end

  def upload_logs(logs, type)
    S3Service.store_file("#{folder_name}/#{file_name(type)}", logs.join("\n"))
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
