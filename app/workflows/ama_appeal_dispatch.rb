# frozen_string_literal: true

class AmaAppealDispatch
  include ActiveModel::Model
  include DecisionDocumentValidator

  def initialize(appeal:, params:, user:, mail_request: nil)
    @appeal = appeal
    @params = params.merge(appeal_id: appeal.id, appeal_type: "Appeal")
    @user = user
    @citation_number = params[:citation_number]
    @decision_date = params[:decision_date]
    @redacted_document_location = params[:redacted_document_location]
    @file = params[:file]
    @mail_request = mail_request
  end

  def call
    throw_error_if_no_tasks_or_if_task_is_completed
    throw_error_if_file_number_not_match_bgs

    @success = valid?

    outcode_appeal if success

    queue_mail_request_job unless @mail_request.nil?

    FormResponse.new(success: success, errors: [errors.full_messages.join(", ")])
  end

  private

  attr_reader :appeal, :params, :user, :success, :citation_number,
              :decision_date, :redacted_document_location, :file

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
    DecisionDocument.create!(params).tap(&:submit_for_processing!)
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

  # Queues mail request job if recipient info present and dispatch completed
  def queue_mail_request_job
    return unless dispatch_task.root_task.status == Constants.TASK_STATUSES.completed

    MailRequestJob.perform_later(@file, @mail_request)
    info_message = "MailRequestJob for citation #{@citation_number} queued for submission to Package Manager"
    log_info(info_message)
  end

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + " ID: " + uuid)
  end
end
