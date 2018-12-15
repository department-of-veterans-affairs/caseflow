class RootTask < GenericTask
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if
      MailTeam.singleton.user_has_access?(user)

    return [Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h] if
      HearingsManagement.singleton.user_has_access?(user) &&
      legacy? &&
      children.select do |t|
        t.is_a?(ScheduleHearingTask) &&
        t.status != Constants.TASK_STATUSES.completed
      end.empty?

    []
  end

  def actions_available?(_user)
    return false if completed?
    true
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      create_vso_subtask!(appeal, root_task)
    end

    private

    def create_vso_subtask!(appeal, parent)
      appeal.vsos.each do |vso_organization|
        InformalHearingPresentationTask.create(
          appeal: appeal,
          parent: parent,
          status: Constants.TASK_STATUSES.in_progress,
          assigned_to: vso_organization
        )
      end
    end
  end
end
