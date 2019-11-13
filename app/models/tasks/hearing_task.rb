# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.

class HearingTask < Task
  has_one :hearing_task_association
  delegate :hearing, to: :hearing_task_association, allow_nil: true
  before_validation :set_assignee

  class HearingTaskNotCompletable < StandardError; end

  def self.label
    "All hearing-related tasks"
  end

  def default_instructions
    [COPY::HEARING_TASK_DEFAULT_INSTRUCTIONS]
  end

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

  def hearing_task_ready_for_completion?
    return false if !appeal.tasks.open.where(type: HearingTask.name).empty?

    if appeal.in_caseflow_location?
      true
    else
      fail HearingTaskNotCompletable
    end
  end

  def when_child_task_completed(child_task)
    super

    return unless hearing_task_ready_for_completion?

    if appeal.is_a?(LegacyAppeal)
      update_legacy_appeal_location
    else
      IhpTasksFactory.new(parent).create_ihp_tasks!
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

  def create_change_hearing_disposition_task(instructions = nil)
    task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    active_disposition_tasks = children.open.where(type: task_names).to_a

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
    children.open.detect { |child| child.type == AssignHearingDispositionTask.name }
  end

  private

  def cascade_closure_from_child_task?(_child_task)
    true
  end

  def send_alert_of_attempted_location_move
    capture_exception(HearingTaskNotCompletable.new, extra: { task_id: id, location_code: appeal.location_code })
  end

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def update_status_if_children_tasks_are_closed(_child_task)
    if children.open.empty? && children.select do |child|
         child.type == AssignHearingDispositionTask.name && child.cancelled?
       end .any?
      return update!(status: :cancelled)
    end

    super
  end
end
