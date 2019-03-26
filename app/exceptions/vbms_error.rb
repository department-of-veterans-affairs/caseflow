# frozen_string_literal: true

# Wraps known VBMS errors so that we can better triage what gets reported in Sentry alerts.
class VBMSError < RuntimeError
  def initialize(error)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
    end
  end

  KNOWN_ERRORS = {
    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/
    "additional review due to an Incident Flash" => "VBMS::IncidentFlashError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4035/
    "Could not access remote service at" => "VBMS::TransientError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3405/
    "Unable to associate rated issue, rated issue does not exist" => "VBMS::RatedIssueMissingError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3894/
    "Requested result set exceeds acceptable size." => "VBMS::DocumentTooBigError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3293/
    "WssVerification Exception - Security Verification Exception" => "VBMS::SecurityError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3965/
    "VBMS is currently unavailable due to maintenance." => "VBMS::DownForMaintenanceError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3274/
    "The data value of the PostalCode did not satisfy" => "VBMS::BadPostalCodeError",

    "ClaimNotFoundException thrown in findContentions for ClaimID" => "VBMS::ClaimNotFoundError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3276/events/270914/
    "A PIF for this EP code already exists." => "VBMS::PIFExistsForEPCodeError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/events/271178/
    "A duplicate claim for this EP code already exists in CorpDB" => "VBMS::DuplicateEPError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3467/events/276980/
    "User is not authorized." => "VBMS::UserNotAuthorizedError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3467/events/278342/
    "Unable to establish claim: " => "VBMS::BadClaimError",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4164/events/279584/
    "The contention is connected to an issue in ratings and cannot be deleted." => "VBMS::CannotDeleteContentionError"
  }.freeze

  class << self
    def from_vbms_http_error(vbms_http_error)
      error_message = extract_error_message(vbms_http_error)
      new_error = nil
      KNOWN_ERRORS.each do |msg_str, error_class_name|
        next unless error_message =~ /#{msg_str}/

        new_error = error_class_name.constantize.new(vbms_http_error)
        break
      end
      new_error ||= new(vbms_http_error)
    end

    private

    def extract_error_message(vbms_http_error)
      if vbms_http_error.try(:body)
        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3124/
        vbms_http_error.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      else
        vbms_http_error.message
      end
    end
  end
end

class VBMS::IncidentFlashError < StandardError; end
class VBMS::TransientError < StandardError; end
class VBMS::RatedIssueMissingError < StandardError; end
class VBMS::DocumentTooBigError < StandardError; end
class VBMS::SecurityError < StandardError; end
class VBMS::DownForMaintenanceError < StandardError; end
class VBMS::BadPostalCodeError < StandardError; end
class VBMS::ClaimNotFoundError < StandardError; end
class VBMS::PIFExistsForEPCodeError < StandardError; end
class VBMS::DuplicateEPError < StandardError; end
class VBMS::UserNotAuthorizedError < StandardError; end
class VBMS::BadClaimError < StandardError; end
class VBMS::CannotDeleteContentionError < StandardError; end
