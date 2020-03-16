# frozen_string_literal: true

##
# Endpoint to return the columns for the frontend with the filter values.

class Hearings::ScheduleHearingTasksColumnsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_edit_hearing_schedule_access

  def index
    tab = AssignHearingTab.new(
      appeal_type: appeal_type,
      regional_office_key: allowed_params[:regional_office_key]
    )

    render json: tab.to_hash
  end

  private

  def allowed_params
    params.permit(
      Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM,
      :regional_office_key
    )
  end

  def appeal_type
    case allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM]
    when Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME
      Appeal.name
    when Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME
      LegacyAppeal.name
    else
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM,
        message: "Tab does not exist"
      )
    end
  end
end
