# frozen_string_literal: true

# Controller to create CAVC Remands and kick off a new Appeal stream on an appeal

class CavcRemandsController < ApplicationController
  before_action :validate_cavc_remand_access

  def create
    cavc_remand = CavcRemand.create!(create_params)
    render json: { cavc_remand: cavc_remand, cavc_appeal: cavc_remand.remand_appeal }, status: :created
  end

  #  def update
  # only for mdr, not yet implemented
  #  end

  private

  def source_appeal
    @source_appeal ||= Appeal.find_by_uuid(params[:source_appeal_id])
  end

  def validate_cavc_remand_access
    unless CavcLitigationSupport.singleton.user_has_access?(current_user)
      msg = "Only CAVC Litigation Support users can create CAVC Remands"
      fail Caseflow::Error::ActionForbiddenError, message: msg
    end
  end

  def create_params
    params.merge!(created_by_id: current_user.id, updated_by_id: current_user.id, source_appeal_id: source_appeal.id)
    params.require(required_params)
    params.permit(required_params << :remand_subtype).merge(params.permit(decision_issue_ids: []))
  end

  def required_params
    [
      :source_appeal_id,
      :cavc_decision_type,
      :cavc_docket_number,
      :cavc_judge_full_name,
      :created_by_id,
      :decision_date,
      :decision_issue_ids,
      :instructions,
      :judgement_date,
      :mandate_date,
      :represented_by_attorney,
      :updated_by_id
    ]
  end
end
