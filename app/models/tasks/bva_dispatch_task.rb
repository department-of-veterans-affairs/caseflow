class BvaDispatchTask < GenericTask
  include RoundRobinAssigner

  class << self
    def create_and_assign(root_task)
      parent = create!(assigned_to: BvaDispatch.singleton, parent_id: root_task.id, appeal: root_task.appeal)
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
      Decision.create!(params)

      task.mark_as_complete!
      task.root_task.mark_as_complete!
    end

    private

    def list_of_assignees
      Constants::BvaDispatchTeams::USERS[Rails.current_env]
    end
  end
end
