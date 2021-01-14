# frozen_string_literal: true

##
# The DocketSwitchTaskHandler handles cancelling, moving, and creating tasks to support Docket Switches.

class DocketSwitchTaskHandler
  include ActiveModel::Model

  validates :docket_switch, presence: true

  attr_accessor :docket_switch, :selected_task_ids, :new_admin_actions

  def initialize(args)
    super

    @selected_task_ids ||= []
    @new_admin_actions ||= []

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  delegate :old_docket_stream, :new_docket_stream, :disposition, to: :docket_switch
  delegate :stream_change_tasks, to: :old_docket_stream

  # New tasks are created on the new stream first so that the new root and distribution tasks are available
  # parents when copying the persistent tasks to the new stream.
  # Copying persistent tasks happens before cancelling the old tasks in order to preserve the current state of the task
  def call
    return if disposition == "denied"

    create_new_tasks!
    copy_persistent_tasks!
    cancel_old_tasks!
  end

  private

  # The persistent tasks are the subset of open tasks with no children the user selected to move to the new stream
  # This copies each task and its ancestors, eventually connecting the branch to the new distribution or root task
  def copy_persistent_tasks!
    persistent_tasks.each { |task| task.copy_to_new_stream!(new_docket_stream) }
  end

  # For full grants, cancel all tasks on the original stream
  # For partial grants, some tasks remain open such as root, distribution and tasks related to the original docket
  # Other tasks can be closed or moved to the new stream (as selected by the user)
  def cancel_old_tasks!
    if disposition == "granted"
      old_docket_stream.cancel_active_tasks
    else
      stream_change_tasks.each(&:cancel_task_and_child_subtasks)
    end
  end

  # Create new tasks automatically creates the docket-related tasks on the new stream
  # As well as any new admin actions added by the user
  def create_new_tasks!
    new_docket_stream.create_tasks_on_intake_success!
    params_array = new_admin_actions.map do |task|
      task.merge(appeal: new_docket_stream, parent: new_docket_stream.root_task)
    end

    ColocatedTask.create_many_from_params(params_array, attorney_user)
  end

  def persistent_tasks
    @persistent_tasks ||= stream_change_tasks.select { |task| selected_task_ids.include?(task.id) }
  end

  def attorney_user
    granted_task = old_docket_stream.tasks.find { |task| task.is_a?(DocketSwitchGrantedTask) }

    granted_task&.assigned_to
  end
end
