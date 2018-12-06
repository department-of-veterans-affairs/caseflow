class RootTask < GenericTask
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def available_actions(_user)
    [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h]
  end

  def no_actions_available?(user)
    !(MailTeam.singleton.user_has_access?(user) && status != Constants.TASK_STATUSES.completed)
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      create_vso_subtask!(appeal, root_task)
    end

    private

    def create_vso_subtask!(appeal, parent)
      appeal.vsos.each do |vso_organization|
        VsoAppeal.create(
          organization: vso_organization,
          appeal: appeal
        )

        if appeal.hearings.empty? && vso_organization.ihp_writing_vso
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

  def can_be_accessed_by_user?(user)
    return true if HearingsManagement.singleton.user_has_access?(user)

    super(user)
  end
end
