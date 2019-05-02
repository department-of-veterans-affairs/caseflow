# frozen_string_literal: true

class Tasks::AssignToPulacCerulloController < ApplicationController
  def create
    task = task_params
    Task.create!(
      type: task[:type],
      appeal: Appeal.find_by(id: task[:appeal][:id]),
      assigned_by_id: task[:assignedTo][:id],
      parent_id: task[:id],
      assigned_to: PulacCurello.singleton
    )
  end

  def task_params
    params[:task]
  end
end
