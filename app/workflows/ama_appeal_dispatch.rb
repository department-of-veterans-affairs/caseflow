# frozen_string_literal: true

class AmaAppealDispatch
  include ActiveModel::Model
  include DecisionDocumentValidator

  def initialize(appeal:, params:, user:, mail_package: nil)
    @params = params.merge(appeal_id: appeal.id, appeal_type: "Appeal")
    @appeal = appeal
    @user = user
    @mail_package = mail_package
  end

  def call
    throw_error_if_no_tasks_or_if_task_is_completed
    throw_error_if_file_number_not_match_bgs

    @success = valid?

    outcode_appeal if success

    FormResponse.new(success: success, errors: [errors.full_messages.join(", ")])
  end

  private

  attr_reader :params, :appeal, :user, :mail_package, :success

  def citation_number
    params[:citation_number]
  end

  def decision_date
    params[:decision_date]
  end

  def redacted_document_location
    params[:redacted_document_location]
  end

  def file
    params[:file]
  end

  def dispatch_tasks
    @dispatch_tasks ||= BvaDispatchTask.not_cancelled.where(appeal: appeal, assigned_to: user)
  end

  def dispatch_task
    @dispatch_task ||= dispatch_tasks[0]
  end

  def throw_error_if_file_number_not_match_bgs
    if FileNumberUpdateDetector.new(veteran: @appeal.veteran).new_file_number.present?
      fail(
        Caseflow::Error::BgsFileNumberMismatch,
        appeal_id: appeal.id, user_id: user.id, veteran_id: @appeal.veteran.id
      )
    end
  end

  def throw_error_if_no_tasks_or_if_task_is_completed
    if dispatch_tasks.size != 1
      fail(
        Caseflow::Error::BvaDispatchTaskCountMismatch,
        appeal_id: appeal.id, user_id: user.id, tasks: dispatch_tasks
      )
    end

    if dispatch_task.completed?
      fail(
        Caseflow::Error::BvaDispatchDoubleOutcode,
        appeal_id: appeal.id, task_id: dispatch_task.id
      )
    end
  end

  def outcode_appeal
    create_decision_document_and_submit_for_processing!(params)
    complete_dispatch_task!
    complete_dispatch_root_task!
    close_request_issues_as_decided!
    store_poa_participant_id
    DeNovoStreamCreator.new(appeal).call
  end

  def create_decision_document_and_submit_for_processing!(params)
    DecisionDocument.create_document!(params, mail_package).tap(&:submit_for_processing!)
  end

  def complete_dispatch_task!
    dispatch_task.update!(status: Constants.TASK_STATUSES.completed)
  end

  def complete_dispatch_root_task!
    dispatch_task.root_task.update!(status: Constants.TASK_STATUSES.completed)
  end

  def close_request_issues_as_decided!
    appeal.request_issues.each(&:close_decided_issue!)
  end

  def store_poa_participant_id
    appeal.update!(poa_participant_id: appeal.power_of_attorney&.participant_id)
  end
end
