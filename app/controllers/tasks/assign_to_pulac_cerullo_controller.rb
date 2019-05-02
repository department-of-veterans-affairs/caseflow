# frozen_string_literal: true

class Tasks::AssignToPulacCerulloController < ApplicationController
  def create
    task = task_params
    task_appeal_id = task[:appeal][:id]
    assigned_by_id = task[:assignedTo][:id]
    parent_task_id = task[:uniqueId]
    child_task = Task.create!(
      type: task[:type],
      appeal: appeal,
      assigned_by_id: assigned_by_id,
      parent_id: parent_task_id,
      assigned_to: PulacCurello.singleton
    )
    # dont know why its still showing up in the lit support organization queue
    Task.find_by(id: parent_task_id).update!(status: "assigned")
    render json: {
      child_task_assigned_to_pulac_cerullo: child_task
    }

  end
  private

  def task_params
    params[:task]
  end

  def appeal
    @appeal ||= Appeal.find_by(id: params[:task][:appeal][:id])
  end
end
