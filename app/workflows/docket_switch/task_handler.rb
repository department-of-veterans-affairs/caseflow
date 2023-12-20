# frozen_string_literal: true

##
# The DocketSwitch::TaskHandler handles cancelling, moving, and creating tasks to support Docket Switches.

# Notes on logic order in the call method:
# New tasks are created on the new stream first so that the new root and distribution tasks are available
# parents when copying the persistent tasks to the new stream.
# Copying persistent tasks happens before cancelling the old tasks in order to preserve the current state of the task
# And are saved after cancelling the tasks to prevent duplicate Org tasks per docket number

class DocketSwitch::TaskHandler
  include ActiveModel::Model

  validates :docket_switch, presence: true

  attr_accessor :docket_switch, :selected_task_ids, :new_admin_actions

  def initialize(args)
    super

    @selected_task_ids ||= []
    @new_admin_actions ||= []

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  delegate :old_docket_stream, :new_docket_stream, :disposition, :docket_type, to: :docket_switch
  delegate :docket_switchable_tasks, to: :old_docket_stream

  def call
    complete_docket_switch_tasks

    return if disposition == "denied"

    create_new_tasks
    tasks_to_move = copy_persistent_tasks
    cancel_old_tasks
    tasks_to_move.each { |task| task.save(validate: false) }
  end

  private

  def complete_docket_switch_tasks
    DocketSwitchAbstractAttorneyTask.where(appeal: old_docket_stream).update(status: Constants.TASK_STATUSES.completed)
    DocketSwitchRulingTask.where(appeal: old_docket_stream).update(status: Constants.TASK_STATUSES.completed)
  end

  # For full grants, cancel all tasks on the original stream
  # For partial grants, some tasks remain open such as root, distribution and tasks related to the original docket
  # Post-distribution tasks also remain open if the original stream remains active
  # Other tasks can be selected (moved to the new stream), or cancelled without moving
  # Note: there is not currently an option to keep switchable tasks open on the original stream for a partial grant
  def cancel_old_tasks
    if disposition == "granted"
      old_docket_stream.cancel_active_tasks
    else
      docket_switchable_tasks.reject(&:post_distribution?).each(&:cancel_task_and_child_subtasks)
    end
  end

  # Create new tasks automatically creates the docket-related tasks on the new stream
  # As well as any new admin actions added by the user
  def create_new_tasks
    new_docket_stream.create_tasks_on_intake_success!
    params_array = new_admin_actions.map do |task|
      task.merge(appeal: new_docket_stream, parent: new_docket_stream.root_task)
    end

    ColocatedTask.create_many_from_params(params_array, attorney_user)
  end

  # When switching to Evidence Submission or Hearing, the new stream goes through distribution again
  # with the new pre-distribution requirements, so post-distribution tasks aren't copied over.
  # Direct Review is the opposite; if there are post-distribution tasks, we preserve them and
  # cancel the DistributionTask to prevent double distribution.
  def copy_persistent_tasks
    tasks_to_copy = docket_switchable_tasks.select { |task| selected_task_ids.include?(task.id.to_s) }
    if docket_type == "direct_review"
      new_docket_stream.tasks.find_by(type: "DistributionTask").cancelled! if tasks_to_copy.any?(&:post_distribution?)
    else
      tasks_to_copy.reject!(&:post_distribution?)
    end
    tasks_to_copy.map { |task| task.copy_with_ancestors_to_stream(new_docket_stream) }
  end

  def attorney_user
    granted_task = old_docket_stream.tasks.assigned_to_any_user.find_by(type: "DocketSwitchGrantedTask")

    granted_task&.assigned_to
  end
end
