# frozen_string_literal: true

##
# Root task that tracks an appeal all the way through the appeal lifecycle.
# This task is closed when an appeal has been completely resolved.

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

  def actions_available?(_user)
    true
  end

  def actions_allowable?(_user)
    true
  end

  def assigned_to_label
    COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      create_vso_tracking_tasks(appeal, root_task)
      if FeatureToggle.enabled?(:ama_acd_tasks)
        create_subtasks!(appeal, root_task)
      else
        create_ihp_tasks!(appeal, root_task)
      end
    end

    def create_ihp_tasks!(appeal, parent)
      appeal.representatives.select { |org| org.should_write_ihp?(appeal) }.map do |vso_organization|
        # For some RAMP appeals, this method may run twice.
        existing_task = InformalHearingPresentationTask.find_by(
          appeal: appeal,
          assigned_to: vso_organization
        )
        existing_task || InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: parent,
          assigned_to: vso_organization
        )
      end
    end

    # TODO: make this private again after RAMPs are refilled
    # private

    def create_vso_tracking_tasks(appeal, parent)
      appeal.representatives.map do |vso_organization|
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
      ScheduleHearingTask.create!(appeal: appeal, parent: parent)
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
