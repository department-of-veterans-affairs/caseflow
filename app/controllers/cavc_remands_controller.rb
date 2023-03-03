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

  APPELLANT_SUBSTITUTION_PARAMS = [
    :substitution_date,
    :participant_id,
    :remand_source,
    :is_appellant_substituted,
    :created_by_id,
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
    if FeatureToggle.enabled?(:cavc_remand_granted_substitute_appellant)
      create_appeal_and_cavc_remand_appellant_substitutions(cavc_appeal, new_cavc_remand)
    end
    render json: { cavc_remand: new_cavc_remand, cavc_appeal: cavc_appeal }, status: :created
  end

  def update
    cavc_appeal = cavc_remand.remand_appeal
    if params["source_form"] == "add_cavc_dates_modal" # EditCavcTodo: replace all occurrences with a constant
      cavc_remand.add_cavc_dates(add_cavc_dates_params.except(:source_form))
    else
      cavc_remand.update(creation_params.except(:source_form))
      if FeatureToggle.enabled?(:cavc_remand_granted_substitute_appellant)
        appellant_substitution = appeal.appellant_substitution
        if appellant_substitution.blank?
          create_appeal_and_cavc_remand_appellant_substitutions(cavc_appeal, cavc_remand)
        else
          update_appeal_and_cavc_remand_appellant_substitutions(cavc_appeal, cavc_remand)
        end
      end
    end

    render json: {
      cavc_remand: WorkQueue::CavcRemandSerializer.new(cavc_remand).serializable_hash[:data][:attributes],
      cavc_appeal: cavc_appeal
    }, status: :ok
  end

  private

  def update_appeal_and_cavc_remand_appellant_substitutions(cavc_appeal, new_cavc_remand)
    if params[:is_appellant_substituted].present?
      appellant_substitution.update(updated_by_id: current_user.id,
                                    substitution_date: params[:substitution_date],
                                    substitute_participant_id: params[:participant_id])
    else
      appellant_substitution.update(updated_by_id: current_user.id,
                                    substitution_date: Date.current,
                                    substitute_participant_id: cavc_remand.veteran.participant_id)
      cavc_appeal.update(veteran_is_not_claimant: nil)
    end
    cavc_remands_appellant_substitution = new_cavc_remand.cavc_remands_appellant_substitution
    cavc_remands_appellant_substitution.update(
      cavc_remand_appellant_substitution_params.merge!(substitute_participant_id: params[:participant_id])
      .except(:created_by_id)
    )
  end

  def create_appeal_and_cavc_remand_appellant_substitutions(cavc_appeal, new_cavc_remand)
    if params[:participant_id].present?
      appellant_substitution = AppellantSubstitution.create(created_by_id: current_user.id,
                                                            source_appeal_id: cavc_appeal.id,
                                                            substitution_date: params[:substitution_date],
                                                            claimant_type: "DependentClaimant",
                                                            substitute_participant_id: params[:participant_id])
    end
    CavcRemandsAppellantSubstitution.create(
      cavc_remand_appellant_substitution_params.merge!(
        cavc_remand_id: new_cavc_remand.id,
        substitute_participant_id: params[:participant_id],
        appellant_substitution_id: appellant_substitution&.id
      )
    )
  end

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

  def cavc_remand_appellant_substitution_params
    params.merge!(created_by_id: current_user.id, updated_by_id: current_user.id)
    params.permit(APPELLANT_SUBSTITUTION_PARAMS)
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
