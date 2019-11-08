# frozen_string_literal: true

##
# Changes to hearings-related tasks often also require changing the associated hearing
# or creating additional tasks.
# This class manages the flow of data changes from the creation of the initial HearingTask tree,
# to scheduling a veteran, changing the disposition after the hearing date, and finally completing the HearingTask
#
# See hearings-related tasks:
# HearingTask, ScheduleHearingTask, NoShowHearingTask, AssignHearingDispositionTask, and ChangeHearingDispositionTask

class Hearings::WorkflowManager
  attr_reader :hearing_task, :appeal, :hearing

  def initialize(hearing_task)
    @hearing_task = hearing_task
    @appeal = hearing_task&.appeal
    @hearing = hearing_task&.hearing
  end

  def self.start_ama_task_tree(distribution_task:)
    ScheduleHearingTask.create!(appeal: distributinon_task.appeal, parent: distribution_task)
  end

  def self.start_legacy_task_tree(root_task:)
    ScheduleHearingTask.create!(appeal: root_task.appeal, parent: root_task)
    AppealRepository.update_location!(root_task.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
  end

  def scheduler
    @scheduler ||= Hearings::Schedule.new(appeal, hearing_task: hearing_task)
  end

  def disposition
    @disposition ||= Hearings::Disposition.new(hearing_task, scheduler: scheduler)
  end

  def withdraw!
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.withdraw_hearing!(appeal)
      AppealRepository.update_location!(appeal, legacy_withdrawal_location)
    else
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: hearing_task.parent,
        assigned_to: MailTeam.singleton
      )
    end
  end

  def complete!
    if appeal.is_a?(LegacyAppeal)
      update_legacy_appeal_location
    else
      IhpTasksFactory.new(parent).create_ihp_tasks!
    end
  end

  private

  def update_legacy_appeal_location
    location = if hearing&.held?
                 LegacyAppeal::LOCATION_CODES[:transcription]
               elsif appeal.representatives.empty?
                 LegacyAppeal::LOCATION_CODES[:case_storage]
               else
                 LegacyAppeal::LOCATION_CODES[:service_organization]
               end

    AppealRepository.update_location!(appeal, location)
  end
end
