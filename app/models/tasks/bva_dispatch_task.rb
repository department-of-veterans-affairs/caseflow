class BvaDispatchTask < GenericTask
  include RoundRobinAssigner

  class << self
    def create_and_assign(root_task)
      parent = create!(
        assigned_to: BvaDispatch.singleton,
        parent_id: root_task.id,
        appeal: root_task.appeal,
        status: Constants.TASK_STATUSES.on_hold
      )
      create!(
        appeal: parent.appeal,
        parent_id: parent.id,
        assigned_to: next_assignee
      )
    end

    def outcode(appeal, params, user)
      tasks = where(appeal: appeal, assigned_to: user)
      if tasks.count != 1
        fail Caseflow::Error::BvaDispatchTaskCountMismatch, appeal_id: appeal.id, user_id: user.id, tasks: tasks
      end

      task = tasks[0]

      fail(Caseflow::Error::BvaDispatchDoubleOutcode, appeal_id: appeal.id, task_id: task.id) if task.completed?

      params[:appeal_id] = appeal.id

      create_decision_document!(params)

      task.mark_as_complete!
      task.root_task.mark_as_complete!
    rescue ActiveRecord::RecordInvalid => e
      raise(Caseflow::Error::OutcodeValidationFailure, mark_as_completessage: e.message) if e.message.match?(/^Validation failed:/)
      raise e
    end

    private

    def list_of_assignees
      BvaDispatch.singleton.users.order(:id).pluck(:css_id)
    end

    def create_decision_document!(params)
      DecisionDocument.create!(params).tap do |decision_document|
        decision_document.submit_for_processing!
        ProcessDecisionDocumentJob.set(wait: DecisionDocument::DECISION_OUTCODING_DELAY).perform_later(decision_document)
      end
    end
  end
end
