# frozen_string_literal: true

class BulkTaskAssignmentsController < ApplicationController
  def create
    bulk_task_assignment = BulkTaskAssignment.new(*bulk_task_assignment_params)
    return invalid_record_error(bulk_task_assignment) unless bulk_task_assignment.valid?
  end

  private

  def bulk_task_assignment_params
    params.require(:bulk_task_assignment).permit(:assign_to, :task_type, :task_count)
  end
end
