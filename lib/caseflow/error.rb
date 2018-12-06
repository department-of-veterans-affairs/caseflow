module Caseflow::Error
  module ErrorSerializer
    extend ActiveSupport::Concern

    def initialize(args)
      @code = args[:code]
      @message = args[:message]
    end

    def serialize_response
      { json: { "errors": [{ "status": code, "title": message, "detail": message }] }, status: code }
    end
  end

  class SerializableError < StandardError
    include Caseflow::Error::ErrorSerializer
    attr_accessor :code, :message
  end

  class EfolderError < SerializableError; end
  class DocumentRetrievalError < EfolderError; end
  class EfolderAccessForbidden < EfolderError; end
  class ClientRequestError < EfolderError; end

  class ActionForbiddenError < SerializableError
    def initialize(args)
      @code = args[:code] || 403
      @message = args[:message] || "Action forbidden"
    end
  end

  class NoRootTask < SerializableError
    def initialize(args)
      @task_id = args[:task_id]
      @code = args[:code] || 500
      @message = args[:message] || "Could not find root task for task with ID #{@task_id}"
    end
  end

  class BvaDispatchTaskCountMismatch < SerializableError
    # Add attr_accessors for testing
    attr_accessor :user_id, :appeal_id, :tasks

    def initialize(args)
      @user_id = args[:user_id]
      @appeal_id = args[:appeal_id]
      @tasks = args[:tasks]
      @code = args[:code] || 400
      @message = args[:message] || "Expected 1 BvaDispatchTask received #{@tasks.count} tasks for"\
                                   " appeal #{@appeal_id}, user #{@user_id}"
    end
  end

  class BvaDispatchDoubleOutcode < SerializableError
    attr_accessor :task_id, :appeal_id

    def initialize(args)
      @appeal_id = args[:appeal_id]
      @task_id = args[:task_id]
      @code = args[:code] || 400
      @message = args[:message] || "Appeal #{@appeal_id}, task ID #{@task_id} has already been outcoded. "\
                                   "Cannot outcode the same appeal and task combination more than once"
    end
  end

  class DuplicateOrgTask < SerializableError
    attr_accessor :appeal_id, :task_type, :assignee_type

    def initialize(args)
      @appeal_id = args[:appeal_id]
      @task_type = args[:task_type]
      @assignee_type = args[:assignee_type]
      @code = args[:code] || 400
      @message = args[:message] || "Appeal #{@appeal_id} already has an active task of type #{@task_type} assigned to "\
                                   "#{assignee_type}. No action necessary"
    end
  end

  class OutcodeValidationFailure < SerializableError
    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end

  class DocumentUploadFailedInVBMS < SerializableError
    def initialize(args)
      @code = args[:code] || 502
      @message = args[:message]
    end
  end

  class TooManyChildTasks < SerializableError
    def initialize(args)
      @task_id = args[:task_id]
      @code = args[:code] || 500
      @message = args[:message] || "JudgeTask #{@task_id} has too many children"
    end
  end

  class ChildTaskAssignedToSameUser < SerializableError
    def initialize
      @code = 500
      @message = "A task cannot be assigned to the same user as the parent."
    end
  end

  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
  class InvalidSSN < StandardError; end
  class InvalidFileNumber < StandardError; end
  class MustImplementInSubclass < StandardError; end
  class AttributeNotLoaded < StandardError; end

  class EstablishClaimFailedInVBMS < StandardError
    attr_reader :error_code

    def initialize(error_code)
      @error_code = error_code
    end

    def self.from_vbms_error(error)
      case error.body
      when /PIF is already in use/
        DuplicateEp.new("duplicate_ep")
      when /A duplicate claim for this EP code already exists/
        DuplicateEp.new("duplicate_ep")
      when /The PersonalInfo SSN must not be empty./
        new("missing_ssn")
      when /The PersonalInfo.+must not be empty/
        new("bgs_info_invalid")
      when /The maximum data length for AddressLine1/
        LongAddress.new("long_address")
      else
        error
      end
    end
  end

  class DuplicateEp < EstablishClaimFailedInVBMS; end
  class LongAddress < EstablishClaimFailedInVBMS; end

  class VacolsRepositoryError < StandardError; end
  class VacolsRecordNotFound < VacolsRepositoryError; end
  class UserRepositoryError < VacolsRepositoryError
    include Caseflow::Error::ErrorSerializer
    attr_accessor :code, :message

    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end
  class IssueRepositoryError < VacolsRepositoryError; end
  class QueueRepositoryError < VacolsRepositoryError; end
  class MissingRequiredFieldError < VacolsRepositoryError; end

  class IdtApiError < StandardError; end
  class InvalidOneTimeKey < IdtApiError; end

  # Many BGS calls fail in off-hours because BGS has maintenance time, so it's useful to classify
  # these transient errors and ignore the in our reporting tools. These are marked transient because
  # they're self-resolving and a request can be retried (this typically happens during jobs)
  #
  # Only add new kinds of transient BGS errors when you have investigated that they are expected,
  # and they happen frequently enough to pollute the alerts channel.
  class TransientBGSError < BGSSyncError; end
  class BGSSyncError < StandardError
    attr_reader :error_code

    def initialize(error, end_product_establishment)
      Raven.extra_context(end_product_establishment_id: end_product_establishment.id)
      super(error.message).tap do |result|
        result.set_backtrace(error.backtrace)
      end
    end

    def self.from_bgs_error(error, epe)
      case error.body
      when /WssVerification Exception - Security Verification Exception/
        # A more detailed message is
        #   "WSSecurityException: The message has expired (WSSecurityEngine: Invalid timestamp The
        #    security semantics of the message have expired)"
        #
        # This is a transient error that occasionally happens when client/server timestamps get out of sync
        #
        # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2884/
        TransientBGSError.new("wss_verification_exception", epe)
      when /ShareException thrown in findVeteranByPtcpntId./
        # You may also see "Retrieving Contention list failed. System error." in the body, more
        # context:
        #   "So when the call to get contentions occurred, our BGS call runs through the
        #   Tuxedo layer to get further information, but ran into the issue with BDN and failed the
        #   remainder of the call"
        #
        # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2910/
        TransientBGSError.new("share_exception_find_veteran_by_ptcpnt_id", epe)
      when /Connection timed out - connect(2) for "bepprod.vba.va.gov" port 443/
        # Transient timeouts to BGS because of connectivity issues
        #
        # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2888/
        TransientBGSError.new("connection_timeout_bepprod", epe)
      when /Unable to find SOAP operation: :find_benefit_claim/
        # Transient failure because a VBMS service is unavailable
        #
        # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2891/
        TransientBGSError.new("unable_to_find_soap_operation", epe)
      when /HTTP error (504): upstream request timeout/
        # Transient failure when, for example, a WSDL is unavailable. The originating error could be
        # a Wasabi::Resolver::HTTPError
        #  "Error: 504 for url http://localhost:10001/BenefitClaimServiceBean/BenefitClaimWebService?WSDL"
        #
        # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2928/
        TransientBGSError.new("upstream_504_timeout", epe)
      else
        new(error, epe)
      end
    end
  end
end
