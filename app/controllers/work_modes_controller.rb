# frozen_string_literal: true

class WorkModesController < ApplicationController
  before_action :validate_modification_access_to_overtime

  rescue_from Caseflow::Error::UserRepositoryError do
    redirect_to "/unauthorized"
  end

  def create
    work_mode = WorkMode.create_or_update_by_appeal(appeal, overtime: overtime_param)

    render json: { work_mode: work_mode }
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
