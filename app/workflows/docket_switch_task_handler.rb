# frozen_string_literal: true

##
# The DocketSwitchTaskHandler handles cancelling, moving, and creating tasks to support Docket Switches.

class DocketSwitchTaskHandler
  include ActiveModel::Model

  attr_reader :docket_switch, :selected_task_ids, :new_admin_actions

  def initialize(docket_switch:, selected_task_ids:, new_admin_actions:)
    @docket_switch = docket_switch
    @selected_task_ids = selected_task_ids ||= []
    @new_admin_actions = new_admin_actions ||= []
  end

  delegate :old_docket_stream, :new_docket_stream, :disposition, to: :docket_switch
  delegate :stream_change_tasks, to: :old_docket_stream

  # For this call method, new tasks are created first so that the new root and distribution tasks are available
  # as parents when copying the persistent tasks. Then copying happens before cancelling the old tasks
  # in order to preserve the current state of the task when moving it.
  def call
    return if disposition == "denied"

    create_new_tasks!
    copy_persistent_tasks!
    cancel_old_tasks!
  end

  private

  def copy_persistent_tasks!
    return unless persistent_tasks.any?

    persistent_tasks.each { |task| task.copy_to_new_stream!(new_docket_stream) }
  end

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
      task.merge(appeal: new_docket_stream, parent_id: new_docket_stream.root_task.id)
    end

    ColocatedTask.create_many_from_params(params_array, attorney_user)
  end

  def persistent_tasks
    stream_change_tasks.select { |task| selected_task_ids.include?(task.id) }
  end

  def attorney_user
    granted_task = old_docket_stream.tasks.find { |task| task.is_a?(DocketSwitchGrantedTask) }

    granted_task&.assigned_to
  end
end
