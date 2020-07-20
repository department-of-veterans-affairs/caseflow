# frozen_string_literal: true

# Controller to allow work modes (e.g., overtime) to be modified.
# Only allows judges who have an assigned task on this appeal to toggle overtime.

class WorkModesController < ApplicationController
  before_action :validate_modification_access_to_overtime

  def create
    appeal.overtime = overtime_param
    render json: { work_mode: appeal.work_mode }
  rescue Caseflow::Error::WorkModeCouldNotUpdateError
    render json: { params: params, work_mode: appeal.work_mode }, status: :internal_server_error
  end

  private

  def overtime_param
    ActiveRecord::Type::Boolean.new.deserialize(params.require(:overtime))
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def validate_modification_access_to_overtime
    fail(Caseflow::Error::ActionForbiddenError) unless FeatureToggle.enabled?(:overtime_revamp)

    unless current_user.judge? && current_user_is_assigned_to_appeal?
      msg = "Only judges assigned to this appeal can toggle overtime status"
      fail(Caseflow::Error::ActionForbiddenError, message: msg)
    end

    true
  end

  def current_user_is_assigned_to_appeal?
    # handle case where legacy appeal has an AttorneyLegacyTask assigned by a judge
    return true if appeal.is_a?(LegacyAppeal) && QueueRepository.any_task_assigned_by_user?(appeal, current_user)

    current_user.appeal_has_task_assigned_to_user?(appeal)
  end
end
