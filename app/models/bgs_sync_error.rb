# Many BGS calls fail in off-hours because BGS has maintenance time, so it's useful to classify
# these transient errors and ignore the in our reporting tools. These are marked transient because
# they're self-resolving and a request can be retried (this typically happens during jobs)
#
# Only add new kinds of transient BGS errors when you have investigated that they are expected,
# and they happen frequently enough to pollute the alerts channel.
class BGSSyncError < RuntimeError
  def initialize(error, end_product_establishment)
    Raven.extra_context(end_product_establishment_id: end_product_establishment.id)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def self.from_bgs_error(error, epe)
    error_message = if error.try(:body)
                      # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3124/
                      error.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
                    else
                      error.message
                    end
    # :nocov:
    case error_message
    when /WssVerification Exception - Security Verification Exception/
      # This occasionally happens when client/server timestamps get out of sync. Uncertain why this
      # happens or how to fix it - it only happens occasionally.
      #
      # A more detailed message is
      #   "WSSecurityException: The message has expired (WSSecurityEngine: Invalid timestamp The
      #    security semantics of the message have expired)"
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2884/
      TransientBGSSyncError.new(error, epe)
    when /ShareException thrown in findVeteranByPtcpntId./
      # Some context:
      #   "So when the call to get contentions occurred, our BGS call runs through the
      #   Tuxedo layer to get further information, but ran into the issue with BDN and failed the
      #   remainder of the call"
      #
      # BDN = Benefits Delivery Network
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2910/
      TransientBGSSyncError.new(error, epe)
    when /The Tuxedo service is down/
      #  Similar to above, an outage of connection to BDN.
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2926/
      TransientBGSSyncError.new(error, epe)
    when /Connection timed out - connect\(2\) for "bepprod.vba.va.gov" port 443/
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2888/
      TransientBGSSyncError.new(error, epe)
    when /Connection refused - connect\(2\) for "bepprod.vba.va.gov" port 443/
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3128/
      TransientBGSSyncError.new(error, epe)
    when /HTTPClient::KeepAliveDisconnected: Connection reset by peer/
      # BGS kills connection
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3129/
      TransientBGSSyncError.new(error, epe)
    when /execution expired/
      # Connection timeout
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2935/
      TransientBGSSyncError.new(error, epe)
    when /Connection reset by peer/
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3036/
      TransientBGSSyncError.new(error, epe)
    when /Unable to find SOAP operation:/
      # Transient failure because a VBMS service is unavailable.
      #
      # Examples:
      # :find_benefit_claim
      #   https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2891/
      # :find_veteran_by_file_number
      #   https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3576/
      TransientBGSSyncError.new(error, epe)
    when /HTTP error \(504\): upstream request timeout/
      # Transient failure when, for example, a WSDL is unavailable. For example, the originating
      # error could be a Wasabi::Resolver::HTTPError
      #  "Error: 504 for url http://localhost:10001/BenefitClaimServiceBean/BenefitClaimWebService?WSDL"
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2928/
      TransientBGSSyncError.new(error, epe)
    when /HTTP error \(503\): upstream connect error/
      # Like above
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3573/
      TransientBGSSyncError.new(error, epe)
    when /Unable to parse SOAP message/
      # I don't understand why this happens, but it's transient.
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3404/
      TransientBGSSyncError.new(error, epe)
    when /System error with BGS./
      # Full message may be something like
      # "An error occurred while establishing the claim: Unable to establish claim: TUX-20308 -
      # An unexpected error was encountered. Please contact the System Administrator. Error is: TUX-20308"
      #
      # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3288/
      TransientBGSSyncError.new(error, epe)
    else
      new(error, epe)
    end
    # :nocov:
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
class TransientBGSSyncError < BGSSyncError; end
