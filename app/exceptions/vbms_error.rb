# frozen_string_literal: true

# base class should inherit from StandardError
class Caseflow::Error::VBMS < StandardError
  alias body message
end

# Wraps known VBMS errors so that we can better triage what gets reported in Sentry alerts.
# Inherits from RuntimeError like VBMS::HTTPError does.
class VBMSError < RuntimeError
  class IncidentFlash < Caseflow::Error::VBMS; end
  class Transient < Caseflow::Error::VBMS; end
  class RatedIssueMissing < Caseflow::Error::VBMS; end
  class DocumentTooBig < Caseflow::Error::VBMS; end
  class Security < Caseflow::Error::VBMS; end
  class DownForMaintenance < Caseflow::Error::VBMS; end
  class BadPostalCode < Caseflow::Error::VBMS; end
  class ClaimNotFound < Caseflow::Error::VBMS; end
  class PIFExistsForEPCode < Caseflow::Error::VBMS; end
  class DuplicateEP < Caseflow::Error::VBMS; end
  class UserNotAuthorized < Caseflow::Error::VBMS; end
  class BadClaim < Caseflow::Error::VBMS; end
  class CannotDeleteContention < Caseflow::Error::VBMS; end
  class ClaimDateInvalid < Caseflow::Error::VBMS; end

  attr_accessor :body, :code, :request

  def initialize(error)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
      result.body = error.try(:body)
      result.code = error.try(:code)
      result.request = error.try(:request)
    end
  end

  KNOWN_ERRORS = {
    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4403/events/293678/
    "FAILED FOR UNKNOWN REASONS" => "Transient",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/
    "additional review due to an Incident Flash" => "IncidentFlash",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4035/
    "Could not access remote service at" => "Transient",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3405/
    "Unable to associate rated issue, rated issue does not exist" => "RatedIssueMissing",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3894/
    "Requested result set exceeds acceptable size." => "DocumentTooBig",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3293/
    "WssVerification Exception - Security Verification Exception" => "Security",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3965/
    "VBMS is currently unavailable due to maintenance." => "DownForMaintenance",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3274/
    "The data value of the PostalCode did not satisfy" => "BadPostalCode",

    "ClaimNotFoundException thrown in findContentions for ClaimID" => "ClaimNotFound",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3276/events/270914/
    "A PIF for this EP code already exists." => "PIFExistsForEPCode",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/events/271178/
    "A duplicate claim for this EP code already exists in CorpDB" => "DuplicateEP",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3467/events/276980/
    "User is not authorized." => "UserNotAuthorized",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3467/events/278342/
    "Unable to establish claim: " => "BadClaim",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4164/events/279584/
    "The contention is connected to an issue in ratings and cannot be deleted." => "CannotDeleteContention",

    # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3467/events/292533/
    "The ClaimDateDt value must be a valid date for a claim." => "ClaimDateInvalid"
  }.freeze

  class << self
    def from_vbms_http_error(vbms_http_error)
      error_message = extract_error_message(vbms_http_error)
      new_error = nil
      KNOWN_ERRORS.each do |msg_str, error_class_name|
        next unless error_message =~ /#{msg_str}/

        error_class = "VBMSError::#{error_class_name}".constantize

        new_error = error_class.new(vbms_http_error)
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
