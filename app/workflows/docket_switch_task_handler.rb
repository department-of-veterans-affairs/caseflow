# frozen_string_literal: true

##
# The DocketSwitchTaskHandler handles cancelling, moving, and creating tasks to support Docket Switches.

class DocketSwitchTaskHandler
  include ActiveModel::Model

  attr_reader :docket_switch, :task_selection, :new_admin_actions

  def initialize(docket_switch:, task_selection:, new_admin_actions:)
    @docket_switch = docket_switch
    @task_selection = task_selection ||= {}
    @new_admin_actions = new_admin_actions ||= []
  end

  delegate :old_docket_stream, :new_docket_stream, :disposition, to: :docket_switch

  def call
    return if disposition == "denied"

    copy_persistent_tasks!
    cancel_old_tasks!
    create_new_tasks!
  end

  private

  def copy_persistent_tasks!
    persistent_tasks.each { |task| task.copy_to_new_stream!(new_docket_stream) }
  end

  def cancel_old_tasks!
    if disposition == "granted"
      old_docket_stream.cancel_active_tasks
    else
      old_tasks.each(&:cancel_task_and_child_subtasks)
    end
  end

  def create_new_tasks!
    new_docket_stream.create_tasks_on_intake_success!
    params_array = new_admin_actions.map do |task|
      task.merge(appeal: new_docket_stream, parent_id: new_docket_stream.root_task.id, assigned_to: attorney_user)
    end

    ColocatedTask.create_many_from_params(params_array, attorney_user)
  end

  def old_tasks
    old_docket_stream.tasks.select { |task| task_selection.key?(task.type.to_sym) }
  end

  def persistent_tasks
    old_tasks.select { |task| task_selection[task.type.to_sym] }
  end

  def attorney_user
    granted_task = old_docket_stream.tasks.find { |task| task.is_a?(DocketSwitchGrantedTask) }

    granted_task&.assigned_to
  end
end
