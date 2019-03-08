# frozen_string_literal: true

##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class DispositionTask < GenericTask
  before_create :check_parent_type
  after_update :update_appeal_location_after_cancel, if: :task_just_canceled_and_has_legacy_appeal?
  after_update :create_ihp_tasks_after_cancel, if: :task_just_canceled_and_has_ama_appeal?

  class HearingDispositionNotCanceled < StandardError; end
  class HearingDispositionNotNoShow < StandardError; end

  class << self
    def create_disposition_task!(appeal, parent, hearing)
      DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
    end
  end

  def check_parent_type
    if parent.type != "HearingTask"
      fail(
        Caseflow::Error::InvalidParentTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def cancel!
    if hearing_disposition != Constants.HEARING_DISPOSITION_TYPES.cancelled
      fail HearingDispositionNotCanceled
    end

    update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def mark_no_show!
    if hearing_disposition != Constants.HEARING_DISPOSITION_TYPES.no_show
      fail HearingDispositionNotNoShow
    end

    no_show_hearing_task = NoShowHearingTask.create!(
      parent: self,
      appeal: appeal,
      assigned_to: HearingAdmin.singleton
    )

    no_show_hearing_task.update!(
      status: Constants.TASK_STATUSES.on_hold,
      on_hold_duration: 25.days
    )
  end

  private

  def task_just_canceled?
    saved_change_to_attribute?("status") && cancelled?
  end

  def task_just_canceled_and_has_legacy_appeal?
    task_just_canceled? && appeal.is_a?(LegacyAppeal)
  end

  def task_just_canceled_and_has_ama_appeal?
    task_just_canceled? && appeal.is_a?(Appeal)
  end

  def create_ihp_tasks_after_cancel
    RootTask.create_ihp_tasks!(appeal, parent)
  end

  def update_appeal_location_after_cancel
    location = if appeal.vsos.empty?
                 LegacyAppeal::LOCATION_CODES[:case_storage]
               else
                 LegacyAppeal::LOCATION_CODES[:service_organization]
               end

    AppealRepository.update_location!(appeal, location)
  end

  def hearing_disposition
    parent&.hearing_task_association&.hearing&.disposition
  end
end
