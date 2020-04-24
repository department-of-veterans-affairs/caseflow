# frozen_string_literal: true

class AdvanceOnDocketMotionsController < ApplicationController
  before_action :verify_aod_access

  def create
    AdvanceOnDocketMotion.create_or_update_by_appeal(
      appeal,
      reason: aod_params[:reason],
      granted: aod_params[:granted],
      user_id: current_user.id
    )

    render json: {}
  end

  def verify_aod_access
    fail Caseflow::Error::ActionForbiddenError, message: "User does not belong to AOD team" unless
      AodTeam.singleton.user_has_access?(current_user)
  end

  def aod_params
    params.require(:advance_on_docket_motions).permit(:granted, :reason)
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end
end
