# frozen_string_literal: true

module Caseflow::Error
  module ErrorSerializer
    extend ActiveSupport::Concern

    def initialize(args)
      @code = args[:code]
      @message = args[:message]
      @title = args[:title]
    end

    def serialize_response
      { json: { "errors": [{ "status": code, "title": title || message, "detail": message }] }, status: code }
    end
  end

  class SerializableError < StandardError
    include Caseflow::Error::ErrorSerializer
    attr_accessor :code, :message, :title
  end

  class TransientError < SerializableError
    def ignorable?
      true
    end
  end

  class EfolderError < SerializableError; end
  class DocumentRetrievalError < EfolderError; end
  class EfolderAccessForbidden < EfolderError; end
  class ClientRequestError < EfolderError; end

  class VaDotGovAPIError < SerializableError; end
  class VaDotGovRequestError < VaDotGovAPIError; end
  class VaDotGovServerError < VaDotGovAPIError; end
  class VaDotGovLimitError < VaDotGovAPIError; end
  class VaDotGovAddressCouldNotBeFoundError < VaDotGovAPIError; end
  class VaDotGovMissingFacilityError < VaDotGovAPIError; end
  class VaDotGovInvalidInputError < VaDotGovAPIError; end
  class VaDotGovMultipleAddressError < VaDotGovAPIError; end
  class VaDotGovNullAddressError < StandardError; end
  class VaDotGovForeignVeteranError < StandardError; end

  class FetchHearingLocationsJobError < SerializableError; end

  class ActionForbiddenError < SerializableError
    def initialize(args = {})
      @code = args[:code] || 403
      @message = args[:message] || "Action forbidden"
    end
  end

  class MissingBusinessLine < StandardError
    def initialize
      @message = "No Business Line found"
    end
  end

  class InvalidParameter < SerializableError
    def initialize(args = {})
      @code = args[:code] || 400
      @parameter = args[:parameter] || ""
      @message = args[:message] || "Invalid parameter '#{@parameter}'"
    end
  end

  class NoRootTask < SerializableError
    def initialize(args)
      @task_id = args[:task_id]
      @code = args[:code] || 500
      @message = args[:message] || "Could not find root task for task with ID #{@task_id}"
    end
  end

  class MissingRequiredProperty < SerializableError
    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end

  class InvalidTaskTableTab < SerializableError
    def initialize(args)
      @tab_name = args[:tab_name]
      @code = args[:code] || 400
      @message = args[:message] || "\"#{@tab_name}\" is not a valid tab name"
    end
  end

  class InvalidTaskTableColumnFilter < SerializableError
    def initialize(args)
      @column = args[:column]
      @code = args[:code] || 400
      @message = args[:message] || "Cannot filter table on column: \"#{@column}\""
    end
  end

  class InvalidStatusOnTaskCreate < SerializableError
    def initialize(args)
      @task_type = args[:task_type]
      @code = args[:code] || 400
      @message = args[:message] || "Task status has to be 'assigned' on create for #{@task_type}"
    end
  end

  class MultipleOpenTasksOfSameTypeError < SerializableError
    def initialize(args)
      @task_type = args[:task_type]
      @code = args[:code] || 400
      @title = "Error assigning tasks"
      @message = args[:message] || "Looks like this appeal already has an open #{@task_type} and this action cannot " \
                              "be completed."
    end
  end

  class InvalidUserId < SerializableError
    def initialize(args)
      @user_id = args[:user_id]
      @code = args[:code] || 400
      @message = args[:message] || "\"#{@user_id}\" is not a valid CSS_ID or user ID"
    end
  end

  class InvalidAssigneeStatusOnTaskCreate < SerializableError
    def initialize(args)
      @assignee = args[:assignee]
      @assignee_name = @assignee.is_a?(User) ? @assignee.full_name : @assignee.name
      @code = args[:code] || 400
      @title = args[:title] || "Uh oh! We're unable to assign this to #{@assignee_name}"
      @message = args[:message] || "#{@assignee_name} is marked as #{@assignee.status} in Caseflow. Please select " \
                                   "another #{@assignee.class.name.downcase} assignee or contact support if you " \
                                   "believe you're getting this message in error."
    end
  end

  class IneligibleForBlockedSpecialCaseMovement < SerializableError
    attr_accessor :appeal_id

    def initialize(args)
      @code = args[:code] || 500
      @appeal_id = args[:appeal_id] || nil
      @title = "This appeal cannot be advanced to a judge"
      @message = args[:message] || "Appeal #{@appeal_id} must be awaiting distribution be eligible for Case Movement"
    end
  end

  class IneligibleForSpecialCaseMovement < SerializableError
    attr_accessor :appeal_id

    def initialize(args)
      @code = args[:code] || 500
      @appeal_id = args[:appeal_id] || nil
      @title = "This appeal cannot be advanced to a judge"
      @message = args[:message] || "Appeal #{@appeal_id} must be in Case Storage and not have blocking Mail Tasks to "\
                                   "be eligible for Case Movement"
    end
  end

  class IneligibleForCavcCorrespondence < SerializableError; end

  class InvalidParentTask < SerializableError
    def initialize(args)
      @task_type = args[:task_type]
      @code = args[:code] || 500
      @message = args[:message] || "Invalid parent type for task #{@task_type}"
    end
  end

  class CannotUpdateMandatedRemands < SerializableError
    def initialize
      @message = "Cavc Remands can only be updated if they did not have mandate"
    end
  end

  class JmrAppealDecisionIssueMismatch < SerializableError
    def initialize(args)
      @code = args[:code] || 422
      @decision_issue_ids = args[:decision_issue_ids]
      @appeal_id = args[:appeal_id]
      @message = args[:message] || "JMR remands must include all appeal decision issues."
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

  class BgsFileNumberMismatch < SerializableError
    # Add attr_accessors for testing
    attr_accessor :user_id, :appeal_id

    def initialize(args)
      @user_id = args[:user_id]
      @appeal_id = args[:appeal_id]
      @code = args[:code] || 500
      @title = args[:title] || "VBMS::FilenumberDoesNotExist"
      @message = args[:message] || "The veteran file number does not match the file number in VBMS"
    end
  end

  class RoundRobinTaskDistributorError < SerializableError
    def initialize(args)
      @code = args[:code] || 500
      @message = args[:message] || "RoundRobinTaskDistributor error"
    end
  end

  class AttorneyJudgeCheckoutError < SerializableError
    attr_accessor :code, :message

    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
      @title = args[:title]
    end
  end

  class LegacyCaseAlreadyAssignedError < SerializableError
    attr_accessor :code, :message

    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
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
    attr_accessor :docket_number, :task_type, :assignee_type

    def initialize(args)
      @docket_number = args[:docket_number]
      @task_type = args[:task_type]
      @assignee_type = args[:assignee_type]
      @code = args[:code] || 400
      @title = "Error assigning tasks"
      @message = args[:message] || "Docket (#{@docket_number}) already has an open task type of "\
                                   "#{@task_type} assigned to #{assignee_type}. Please refresh the page. Contact "\
                                   "support if this error persists."
    end
  end

  class DuplicateUserTask < SerializableError
    attr_accessor :docket_number, :task_type

    def initialize(args)
      @docket_number = args[:docket_number]
      @task_type = args[:task_type]
      @code = args[:code] || 400
      @title = "Error assigning tasks"
      @message = args[:message] || "Docket (#{@docket_number}) already has an open task type of "\
                                   "#{@task_type} assigned to a user. Please refresh the page. Contact support if " \
                                   "this error persists."
    end
  end

  class OutcodeValidationFailure < SerializableError
    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end

  class ChildTaskAssignedToSameUser < SerializableError
    def initialize
      @code = 500
      @message = "A task of the same type as the parent task cannot be assigned to the same user."
    end
  end

  class MailRoutingError < SerializableError
    def initialize
      @code = 500
      @message = "Appeal is not active at the Board. Send mail to appropriate Regional Office in mail portal"
    end
  end

  class DuplicateDvcTeam < SerializableError
    def initialize(args)
      @user_id = args[:user_id]
      @code = args[:code] || 400
      @message = args[:message] || "User #{@user_id} already has a DvcTeam. Cannot create another DvcTeam for user."
    end
  end

  class DuplicateJudgeTeam < SerializableError
    def initialize(args)
      @user_id = args[:user_id]
      @code = args[:code] || 400
      @message = args[:message] || "User #{@user_id} already has a JudgeTeam. Cannot create another JudgeTeam for user."
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

    # rubocop:disable Metrics/CyclomaticComplexity
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
      when /VBMS does not currently support claim establishment of claimants with a fiduciary/
        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3276/
        ClaimantWithFiduciary.new("claimant_with_fiduciary")
      else
        error
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end

  class MissingTimerMethod < StandardError; end

  class DuplicateEp < EstablishClaimFailedInVBMS; end
  class LongAddress < EstablishClaimFailedInVBMS; end
  class ClaimantWithFiduciary < EstablishClaimFailedInVBMS; end

  class VacolsRepositoryError < StandardError; end
  class VacolsRecordNotFound < VacolsRepositoryError; end
  class UserRepositoryError < VacolsRepositoryError
    include Caseflow::Error::ErrorSerializer
    attr_accessor :code, :message, :title

    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end
  class IssueRepositoryError < VacolsRepositoryError
    include Caseflow::Error::ErrorSerializer
    attr_accessor :code, :message, :title

    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end
  class RemandReasonRepositoryError < VacolsRepositoryError; end
  class QueueRepositoryError < VacolsRepositoryError; end
  class MissingRequiredFieldError < VacolsRepositoryError; end

  class IdtApiError < StandardError; end
  class InvalidOneTimeKey < IdtApiError; end

  class PexipApiError < SerializableError; end
  class PexipNotFoundError < PexipApiError; end
  class PexipBadRequestError < PexipApiError; end
  class PexipMethodNotAllowedError < PexipApiError; end

  class WorkModeCouldNotUpdateError < StandardError; end

  class VirtualHearingConversionFailed < SerializableError
    attr_accessor :code, :message

    def initialize(args = {})
      @error_type = args[:error_type]
      @code = args[:code]
      @message = args[:message]
    end
  end

  class InvalidEmailError < SerializableError
    attr_accessor :code, :message

    def initialize(args = {})
      @code = args[:code]
      @message = args[:message]
    end
  end
end
