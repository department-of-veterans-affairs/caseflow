class RootTask < Task
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def available_actions(user)
    if MailTeam.singleton.user_has_access?(user)
      return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h]
    end

    []
  end

  def no_actions_available?(user)
    return false if status == Constants.TASK_STATUSES.on_hold && MailTeam.singleton.user_has_access?(user)
    super
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal_id: appeal.id, appeal_type: appeal.class.name)
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

  def can_be_accessed_by_user?(user)
    return true if HearingsManagement.singleton.user_has_access?(user)

    super(user)
  end
end
