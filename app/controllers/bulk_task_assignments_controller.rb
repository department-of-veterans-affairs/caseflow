# frozen_string_literal: true

class BulkTaskAssignmentsController < ApplicationController
  include Errors

  def create
    # only for caseflow tasks
    # - validate that User.find(params[:user_id]) can perform this action (different for Appeal vs LegacyAppeal?)
    # - get list of active bta.task_type tasks assigned to bta.organization)
    #   - sort tasks "oldest" to "newest" (on `created_at`?) (do in model?) maybe oldest appeal?
    #   - slice the first `bulk_task_assignment_params[:task_count]` tasks (do in model?)
    # - step through each task and
    #   - create a new task of the same type with assigned_to = bta.assigned_to and parent = task
    #     - see `create_and_auto_assign_child_task` in the Task model

    bulk_task_assignment = BulkTaskAssignment.new(*bulk_task_assignment_params)
    return invalid_record_error(bulk_task_assignment) unless bulk_task_assignment.valid?

    tasks = bulk_task_assignment.tasks_to_be_assigned

    multi_transaction do
      tasks.each do |task|
        assign_params = {
          assigned_to_type: "User",
          assigned_to_id: bulk_task_assignment.assigned_to.id
        }
        GenericTask.create_child_task(task, current_user, assign_params)
      end
    end

    true
  end

  private

  def bulk_task_assignment_params
    params.require(:bulk_task_assignment).permit(:assigned_to_id, :organization_id, :task_type, :task_count)
  end
end
