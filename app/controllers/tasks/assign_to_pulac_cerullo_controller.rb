# frozen_string_literal: true

class Tasks::AssignToPulacCerulloController < ApplicationController
  def create
    task = task_params
    task_id = task[:appeal][:id]
    assigned_by_id = task[:assignedTo][:id]
    Task.create!(
      type: task[:type],
      appeal: Appeal.find_by(id: task_id),
      assigned_by_id: assigned_by_id,
      parent_id: task[:id],
      assigned_to: PulacCurello.singleton
    )
  end

  def task_params
    params[:task]
  end
end
