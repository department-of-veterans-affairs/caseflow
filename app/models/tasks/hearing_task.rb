# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.

class HearingTask < GenericTask
  has_one :hearing_task_association
  delegate :hearing, to: :hearing_task_association, allow_nil: true
  before_validation :set_assignee

  def cancel_and_recreate
    hearing_task = HearingTask.create!(
      appeal: appeal,
      parent: parent,
      assigned_to: Bva.singleton
    )

    cancel_task_and_child_subtasks

    hearing_task
  end

  def verify_org_task_unique
    true
  end

  def when_child_task_completed
    super

    return unless appeal.tasks.active.where(type: HearingTask.name).empty?

    if appeal.is_a?(LegacyAppeal)
      update_legacy_appeal_location
    else
      RootTask.create_ihp_tasks!(appeal, parent)
    end
  end

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

  def reopen_or_create_change_hearing_disposition_task(instructions = nil)
    disposition_task = children.inactive.detect { |child| child.is_a?(DispositionTask) }
    disposition_task.update!(
      closed_at: nil,
      instructions: [disposition_task.instructions, instructions].flatten.compact,
      status: Constants.TASK_STATUSES.assigned
    )
    if disposition_task.type == DispositionTask.name
      create_change_hearing_disposition_task(instructions)
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    active_disposition_tasks = children.active.where(type: [DispositionTask.name, ChangeHearingDispositionTask.name])

    multi_transaction do
      ChangeHearingDispositionTask.create!(
        appeal: appeal,
        parent: self,
        instructions: instructions.present? ? [instructions] : nil
      )
      active_disposition_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
    end
  end

  def disposition_task
    children.active.detect { |child| child.type == DispositionTask.name }
  end

  private

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def update_status_if_children_tasks_are_complete
    if children.select(&:active?).empty?
      return update!(status: :cancelled) if children.select { |c| c.type == DispositionTask.name && c.cancelled? }.any?
    end

    super
  end
end
