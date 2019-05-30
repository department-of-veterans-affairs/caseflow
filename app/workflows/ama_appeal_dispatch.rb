# frozen_string_literal: true

class AmaAppealDispatch
  def initialize(appeal:, params:, user:)
    @appeal = appeal
    @params = params.merge(appeal_id: appeal.id, appeal_type: "Appeal")
    @user = user
  end

  def call
    throw_error_if_no_tasks_or_if_task_is_completed

    create_decision_document!(params)
    complete_dispatch_task!
    complete_dispatch_root_task!
    close_request_issues_as_decided!
  rescue ActiveRecord::RecordInvalid => error
    if error.message.match?(/^Validation failed:/)
      raise(Caseflow::Error::OutcodeValidationFailure, message: error.message)
    end

    raise error
  end

  private

  attr_reader :appeal, :params, :user

  def dispatch_tasks
    @dispatch_tasks ||= BvaDispatchTask.where(appeal: appeal, assigned_to: user)
  end

  def dispatch_task
    @dispatch_task ||= dispatch_tasks[0]
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

  def create_decision_document!(params)
    DecisionDocument.create!(params).tap do |decision_document|
      delay = if decision_document.decision_date.future?
                decision_document.decision_date + DecisionDocument::PROCESS_DELAY_VBMS_OFFSET_HOURS.hours
              else
                0
              end

      decision_document.submit_for_processing!(delay: delay)

      unless decision_document.processed? || decision_document.decision_date.future?
        ProcessDecisionDocumentJob.perform_later(decision_document.id)
      end
    end
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
end
