# frozen_string_literal: true

# Wraps known VBMS errors so that we can better triage what gets reported in Sentry alerts.
class VBMSError < RuntimeError
  def initialize(error)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
    end
  end

  class << self
    # rubocop:disable Metrics/MethodLength
    def from_vbms_http_error(vbms_http_error)
      error_message = if vbms_http_error.try(:body)
                        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3124/
                        vbms_http_error.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
                      else
                        vbms_http_error.message
                      end

      known_errors = {
        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/
        "additional review due to an Incident Flash" => "VBMS::IncidentFlashError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/4035/
        "Retrieving Contention list failed. System error." => "VBMS::TransientError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3405/
        "Unable to associate rated issue, rated issue does not exist" => "VBMS::RatedIssueMissingError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3894/
        "Requested result set exceeds acceptable size." => "VBMS::DocumentTooBigError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3293/
        "WssVerification Exception - Security Verification Exception" => "VBMS::SecurityError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3965/
        "VBMS is currently unavailable due to maintenance." => "VBMS::DownForMaintenanceError",

        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3274/
        "The data value of the PostalCode did not satisfy the following condition" => "VBMS::BadPostalCodeError"

      }

      new_error = nil
      known_errors.each_key do |msg_str|
        msg = /#{msg_str}/

        next unless msg.match(error_message)

        error_class = known_errors[msg_str].constantize
        new_error = error_class.new(vbms_http_error)
        break
      end
      new_error ||= new(vbms_http_error)
    end
    # rubocop:enable Metrics/MethodLength
  end
end

class VBMS::IncidentFlashError < StandardError; end
class VBMS::TransientError < StandardError; end
class VBMS::RatedIssueMissingError < StandardError; end
class VBMS::DocumentTooBigError < StandardError; end
class VBMS::SecurityError < StandardError; end
class VBMS::DownForMaintenanceError < StandardError; end
class VBMS::BadPostalCodeError < StandardError; end
