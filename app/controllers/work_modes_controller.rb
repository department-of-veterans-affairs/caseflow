# frozen_string_literal: true

# Controller to allow work modes (e.g., overtime) to be modified.
# Only allows judges who have an assigned task on this appeal to toggle overtime.

class WorkModesController < ApplicationController
  before_action :validate_modification_access_to_overtime

  rescue_from Caseflow::Error::UserRepositoryError do
    redirect_to "/unauthorized"
  end

  def create
    appeal.overtime = overtime_param

    render json: { work_mode: appeal.reload.work_mode }
  end

  private

  def overtime_param
    ActiveRecord::Type::Boolean.new.deserialize(params.require(:overtime))
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def validate_modification_access_to_overtime
    current_user.judge? && current_user.appeal_has_task_assigned_to_user?(appeal)
  end
end
