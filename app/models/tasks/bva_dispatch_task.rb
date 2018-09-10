class BvaDispatchTask < GenericTask
  include RoundRobinAssigner

  class << self
    def create_and_assign(root_task)
      parent = create!(assigned_to: BvaDispatch.singleton, parent_id: root_task.id)
      create!(
        appeal: parent.appeal,
        parent_id: parent.id,
        assigned_to: next_assignee
      )
    end

    private

    def list_of_assignees
      Constants::BvaDispatchTeams::USERS[Rails.current_env]
    end
  end
end
