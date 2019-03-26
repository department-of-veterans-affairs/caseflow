# frozen_string_literal: true

class BulkTaskAssignmentsController < ApplicationController
  include Errors

  before_action :verify_task_assignment_access, only: [:create]

  def create
    # no legacy tasks for now (or ever?)
    # - validate that User.find(params[:user_id]) can perform this action (different for Appeal vs LegacyAppeal?)
    # - get list of active bta.task_type tasks assigned to bta.organization)
    #   - sort tasks "oldest" to "newest" (on `created_at`?) (do in model?) maybe oldest appeal?
    #   - slice the first `bulk_task_assignment_params[:task_count]` tasks (do in model?)
    # - step through each task and
    #   - create a new task of the same type with assigned_to = bta.assigned_to and parent = task
    #     - see `create_and_auto_assign_child_task` in the Task model

    bulk_task_assignment = BulkTaskAssignment.new(*bulk_task_assignment_params)
    return invalid_record_error(bulk_task_assignment) unless bulk_task_assignment.valid?
  end

  private

  def bulk_task_assignment_params
    params.require(:bulk_task_assignment).permit(:assigned_to_id, :organization_id, :task_type, :task_count)
  end
end
