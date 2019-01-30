class RootTask < GenericTask
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if MailTeam.singleton.user_has_access?(user) && ama?
    return [Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h] if can_create_schedule_hearings_task?(user)

    []
  end

  def can_create_schedule_hearings_task?(user)
    HearingsManagement.singleton.user_has_access?(user) &&
      !completed? &&
      legacy? &&
      children.where(type: ScheduleHearingTask.name).where.not(status: Constants.TASK_STATUSES.completed).empty?
  end

  def actions_available?(_user)
    true
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      if FeatureToggle.enabled?(:ama_auto_case_distribution)
        create_subtasks!(appeal, root_task)
      else
        create_vso_subtask!(appeal, root_task)
      end
    end

    def create_vso_subtask!(appeal, parent)
      appeal.vsos.map do |vso_organization|
        InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: parent,
          assigned_to: vso_organization
        )
      end
    end

    private

    def create_evidence_submission_task!(appeal, parent)
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end

    def create_distribution_task!(appeal, parent)
      DistributionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton,
        status: "on_hold"
      )
    end

    def create_hearing_tasks!(appeal, parent)
      ScheduleHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: HearingsManagement.singleton
      )
    end

    def create_subtasks!(appeal, parent)
      transaction do
        distribution_task = create_distribution_task!(appeal, parent)

        if appeal.evidence_submission_docket?
          create_evidence_submission_task!(appeal, distribution_task)
        elsif appeal.hearing_docket?
          create_hearing_tasks!(appeal, distribution_task)
        else
          vso_tasks = create_vso_subtask!(appeal, distribution_task)
          # If the appeal is direct docket and there are no ihp tasks,
          # then it is initially ready for distribution.
          distribution_task.ready_for_distribution! if vso_tasks.empty?
        end
      end
    end
  end
end
