# frozen_string_literal: true

# Controller to create CAVC Remands and kick off a new Appeal stream on an appeal

class CavcRemandsController < ApplicationController
  before_action :validate_cavc_remand_access

  def create
    cavc_remand = CavcRemand.create(create_params)
    render json: { cavc_remand: cavc_remand }, status: :created
  end

  #  def update
  # only for mdr, not yet implemented
  #  end

  private

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def validate_cavc_remand_access
    unless LitigationSupport.singleton.user_has_access?(current_user)
      msg = "Only Litigation Support users can create CAVC Remands"
      fail Caseflow::Error::ActionForbiddenError, message: msg
    end
  end

  def create_params
    permitted = params.permit(:judgement_date, :mandate_date, :appeal_id, :cavc_docket_number, :cavc_judge_full_name,
                              :cavc_decision_type, :decision_date, :instructions, :remand_subtype,
                              :represented_by_attorney)
      .merge(params.permit(decision_issue_ids: []))
      .merge(created_by: current_user, updated_by: current_user)
    permitted.require([:appeal_id, :cavc_docket_number, :cavc_judge_full_name, :cavc_decision_type, :decision_date,
                       :decision_issue_ids, :instructions, :remand_subtype, :represented_by_attorney])
    permitted
  end
end
