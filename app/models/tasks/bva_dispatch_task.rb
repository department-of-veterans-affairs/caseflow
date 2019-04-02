# frozen_string_literal: true

##
# Task assigned to BVA Dispatch team members whenever a judge completes a case review.
# This indicates that an appeal is decided and the appellant is about to be notified of the decision.

class BvaDispatchTask < GenericTask
  class << self
    def create_from_root_task(root_task)
      create!(assigned_to: BvaDispatch.singleton, parent_id: root_task.id, appeal: root_task.appeal)
    end

    def outcode(appeal, params, user)
      if ama?(appeal)
        tasks = where(appeal: appeal, assigned_to: user)
        throw_error_if_no_tasks_or_if_task_is_completed(appeal, tasks, user)
        task = tasks[0]
      end

      params[:appeal_id] = appeal.id
      params[:appeal_type] = appeal.class.name
      create_decision_document!(params)

      if ama?(appeal)
        task.update!(status: Constants.TASK_STATUSES.completed)
        task.root_task.update!(status: Constants.TASK_STATUSES.completed)
        appeal.request_issues.each(&:close_decided_issue!)
      end
    rescue ActiveRecord::RecordInvalid => e
      raise(Caseflow::Error::OutcodeValidationFailure, message: e.message) if e.message.match?(/^Validation failed:/)

      raise e
    end

    private

    def ama?(appeal)
      appeal.class.name == Appeal.name
    end

    def create_decision_document!(params)
      DecisionDocument.create!(params).tap do |decision_document|
        delay = decision_document.decision_date.future? ? decision_document.decision_date : 0
        decision_document.submit_for_processing!(delay: delay)

        unless decision_document.processed? || decision_document.decision_date.future?
          ProcessDecisionDocumentJob.perform_later(decision_document.id)
        end
      end
    end

    def throw_error_if_no_tasks_or_if_task_is_completed(appeal, tasks, user)
      if tasks.count != 1
        fail Caseflow::Error::BvaDispatchTaskCountMismatch, appeal_id: appeal.id, user_id: user.id, tasks: tasks
      end

      task = tasks[0]

      fail(Caseflow::Error::BvaDispatchDoubleOutcode, appeal_id: appeal.id, task_id: task.id) if task.completed?
    end
  end
end
