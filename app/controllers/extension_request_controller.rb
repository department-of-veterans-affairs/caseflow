# frozen_string_literal: true

class ExtensionRequestController < TasksController
  def create
    send create_params[:decision]
  end

  def grant
    ActiveRecord::Base.transaction do
      CavcGrantedExtensionRequestTask.create!(extension_params)
      TimedHoldTask.create_from_parent(task, **create_params.to_h.symbolize_keys.except(:decision))
    end

    render json: {}
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  def deny
    CavcDeniedExtensionRequestTask.create!(extension_params)

    render json: {}
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  private

  def task
    @task ||= ::Task.find(params[:task_id])
  end

  def create_params
    params
      .require(:task)
      .permit(:decision, :days_on_hold, instructions: [])
      .merge(assigned_by: current_user)
  end

  def extension_params
    params.require(:task).permit(instructions: [])
      .merge(assigned_by: current_user, assigned_to: current_user, parent: task, appeal: task.appeal)
  end
end
