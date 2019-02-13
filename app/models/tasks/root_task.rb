class RootTask < GenericTask
  # Set assignee to the Bva organization automatically so we don't have to set it when we create RootTasks.
  after_initialize :set_assignee, if: -> { assigned_to_id.nil? }

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def update_children_status
    children.active.where(type: TrackVeteranTask.name).update_all(status: Constants.TASK_STATUSES.completed)
  end

  def hide_from_task_snapshot
    true
  end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if MailTeam.singleton.user_has_access?(user) && ama?

    []
  end

  def can_create_schedule_hearings_task?(user)
    HearingsManagement.singleton.user_has_access?(user) &&
      active? &&
      legacy? &&
      children.active.where(type: ScheduleHearingTask.name).empty?
  end

  def actions_available?(_user)
    true
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      create_vso_tracking_tasks(appeal, root_task)
      if FeatureToggle.enabled?(:ama_auto_case_distribution)
        create_subtasks!(appeal, root_task)
      else
        create_ihp_tasks!(appeal, root_task)
      end
    end

    def create_ihp_tasks!(appeal, parent)
      appeal.vsos.map do |vso_organization|
        InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: parent,
          assigned_to: vso_organization
        )
      end
    end

    private

    def create_vso_tracking_tasks(appeal, parent)
      appeal.vsos.map do |vso_organization|
        TrackVeteranTask.create!(
          appeal: appeal,
          parent: parent,
          assigned_to: vso_organization
        )
      end
    end

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

    def create_hearing_schedule_task!(appeal, parent)
      hearing_task = HearingTask.create!(
        appeal: appeal,
        assigned_to: Bva.singleton,
        parent: parent
      )

      ScheduleHearingTask.create!(
        appeal: appeal,
        parent: hearing_task,
        assigned_to: HearingsManagement.singleton
      )
    end

    def create_subtasks!(appeal, parent)
      transaction do
        distribution_task = create_distribution_task!(appeal, parent)

        if appeal.evidence_submission_docket?
          create_evidence_submission_task!(appeal, distribution_task)
        elsif appeal.hearing_docket?
          create_hearing_schedule_task!(appeal, distribution_task)
        else
          vso_tasks = create_ihp_tasks!(appeal, distribution_task)
          # If the appeal is direct docket and there are no ihp tasks,
          # then it is initially ready for distribution.
          distribution_task.ready_for_distribution! if vso_tasks.empty?
        end
      end
    end
  end
end
