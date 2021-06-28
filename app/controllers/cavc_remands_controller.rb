# frozen_string_literal: true

# Controller to create CAVC Remands and kick off a new Appeal stream on an appeal

class CavcRemandsController < ApplicationController
  before_action :validate_cavc_remand_access

  UPDATE_PARAMS = [
    :instructions,
    :judgement_date,
    :mandate_date,
    :remand_appeal_id
  ].freeze

  REMAND_REQUIRED_PARAMS = [
    :source_appeal_id,
    :cavc_decision_type,
    :cavc_docket_number,
    :cavc_judge_full_name,
    :created_by_id,
    :decision_date,
    :decision_issue_ids,
    :instructions,
    :represented_by_attorney,
    :updated_by_id
  ].freeze

  MDR_REQUIRED_PARAMS = [
    :federal_circuit
  ].freeze

  JMR_REQUIRED_PARAMS = [
    :judgement_date,
    :mandate_date
  ].freeze

  PERMITTED_PARAMS = [
    REMAND_REQUIRED_PARAMS,
    JMR_REQUIRED_PARAMS,
    MDR_REQUIRED_PARAMS,
    :remand_subtype,
    :source_form
  ].flatten.freeze

  def create
    new_cavc_remand = CavcRemand.create!(creation_params)
    cavc_appeal = new_cavc_remand.remand_appeal.reload
    render json: { cavc_remand: new_cavc_remand, cavc_appeal: cavc_appeal }, status: :created
  end

  def update
    if params["source_form"] == "add_cavc_dates_modal" # EditCavcTodo: replace all occurrences with a constant
      cavc_remand.add_cavc_dates(add_cavc_dates_params.except(:source_form))
    else
      cavc_remand.update(creation_params.except(:source_form))
    end

    render json: {
      cavc_remand: WorkQueue::CavcRemandSerializer.new(cavc_remand).serializable_hash[:data][:attributes],
      cavc_appeal: cavc_remand.remand_appeal
    }, status: :ok
  end

  private

  def source_appeal
    @source_appeal ||= Appeal.find_by_uuid(params[:source_appeal_id])
  end

  def cavc_remand
    @cavc_remand ||= CavcRemand.find_by(remand_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id)
  end

  def validate_cavc_remand_access
    unless CavcLitigationSupport.singleton.user_has_access?(current_user)
      msg = "Only CAVC Litigation Support users can create CAVC Remands"
      fail Caseflow::Error::ActionForbiddenError, message: msg
    end
  end

  def add_cavc_dates_params
    params.require(UPDATE_PARAMS)
    params.permit(PERMITTED_PARAMS).except("remand_appeal_id")
  end

  def creation_params
    params.merge!(created_by_id: current_user.id, updated_by_id: current_user.id, source_appeal_id: source_appeal.id)
    params.require(required_params_by_decisiontype_and_subtype)
    params.permit(PERMITTED_PARAMS).merge(params.permit(decision_issue_ids: []))
  end

  def required_params_by_decisiontype_and_subtype
    case params["cavc_decision_type"]
    when Constants.CAVC_DECISION_TYPES.remand
      case params["remand_subtype"]
      when Constants.CAVC_REMAND_SUBTYPES.mdr
        REMAND_REQUIRED_PARAMS + MDR_REQUIRED_PARAMS
      else
        REMAND_REQUIRED_PARAMS + JMR_REQUIRED_PARAMS
      end
    when Constants.CAVC_DECISION_TYPES.straight_reversal, Constants.CAVC_DECISION_TYPES.death_dismissal
      REMAND_REQUIRED_PARAMS
    end
  end
end
