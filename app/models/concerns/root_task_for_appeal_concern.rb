# frozen_string_literal: true

module RootTaskForAppealConcern
  extend ActiveSupport::Concern

  module ClassMethods
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
