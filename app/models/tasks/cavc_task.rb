# frozen_string_literal: true

##
# This task is used to track all related CAVC subtasks.
# If this task is still open, there is still more CAVC-specific work to be done of this appeal.
# This task should be a child of DistributionTask, and so it blocks distribution until all its children are closed.
# TODO: There are no actions available to any user for this task.

class CavcTask < Task
  #  has_one :hearing_task_association
  # delegate :hearing, to: :hearing_task_association, allow_nil: true
  before_validation :set_assignee

  def self.label
    "All CAVC-related tasks"
  end

  def default_instructions
    [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
  end

  def cancel_and_recreate
    cavc_task = CavcTask.create!(
      appeal: appeal,
      parent: parent,
      assigned_to: Bva.singleton
    )

    cancel_task_and_child_subtasks

    cavc_task
  end

  def verify_org_task_unique
    true
  end

  def when_child_task_completed(child_task)
    super

    # do not move forward if there are any open CavcTasks
    return unless appeal.tasks.open.where(type: CavcTask.name).empty?

    # TODO: needed??
    if appeal.is_a?(LegacyAppeal)
      update_legacy_appeal_location
    else
      # IhpTasksFactory.new(parent).create_ihp_tasks!
    end
  end

  # TODO: needed?
  def update_legacy_appeal_location
    # location = if hearing&.held?
    #              LegacyAppeal::LOCATION_CODES[:transcription]
    #            elsif appeal.representatives.empty?
    #              LegacyAppeal::LOCATION_CODES[:case_storage]
    #            else
    #              LegacyAppeal::LOCATION_CODES[:service_organization]
    #            end
    #
    # AppealRepository.update_location!(appeal, location)
  end

  # def create_change_hearing_disposition_task(instructions = nil)
  #   task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
  #   active_disposition_tasks = children.open.where(type: task_names).to_a
  #
  #   multi_transaction do
  #     ChangeHearingDispositionTask.create!(
  #       appeal: appeal,
  #       parent: self,
  #       instructions: instructions.present? ? [instructions] : nil
  #     )
  #     active_disposition_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
  #   end
  # end

  # def disposition_task
  #   children.open.detect { |child| child.type == AssignHearingDispositionTask.name }
  # end

  private

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  # def update_status_if_children_tasks_are_closed(_child_task)
  #   if children.open.empty? && children.select do |child|
  #        child.type == AssignHearingDispositionTask.name && child.cancelled?
  #      end .any?
  #     return update!(status: :cancelled)
  #   end
  #
  #   super
  # end

  def cascade_closure_from_child_task?(_child_task)
    true
  end
end
