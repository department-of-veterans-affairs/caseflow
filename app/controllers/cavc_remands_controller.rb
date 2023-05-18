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

  CAVC_APPELLANT_SUBSTITUTION_PARAMS = [
    :substitution_date,
    :participant_id,
    :remand_source,
    :is_appellant_substituted,
    :created_by_id,
    :updated_by_id
  ].freeze

  EDIT_CAVC_APPELLANT_SUBSTITUTION_PARAMS = [
    selected_task_ids: [],
    cancelled_task_ids: [],
    task_params: {}
  ].freeze

  MDR_REQUIRED_PARAMS = [
    :federal_circuit
  ].freeze

  JMR_JMPR_REQUIRED_PARAMS = [
    :judgement_date,
    :mandate_date
  ].freeze

  PERMITTED_PARAMS = [
    REMAND_REQUIRED_PARAMS,
    JMR_JMPR_REQUIRED_PARAMS,
    MDR_REQUIRED_PARAMS,
    :remand_subtype,
    :source_form
  ].flatten.freeze

  def create
    new_cavc_remand = CavcRemand.create!(creation_params)
    cavc_appeal = new_cavc_remand.remand_appeal&.reload
    if FeatureToggle.enabled?(:cavc_remand_granted_substitute_appellant)
      create_appellant_substitution_and_cavc_remand_appellant_substitution(cavc_appeal, new_cavc_remand)
    end
    render json: { cavc_remand: new_cavc_remand, cavc_appeal: cavc_appeal }, status: :created
  end

  # rubocop:disable Metrics/MethodLength
  def update
    cavc_appeal = cavc_remand.remand_appeal
    if params["source_form"] == "add_cavc_dates_modal" # EditCavcTodo: replace all occurrences with a constant
      cavc_remand.add_cavc_dates(add_cavc_dates_params.except(:source_form))
    else
      cavc_remand.update(creation_params.except(:source_form))
      if FeatureToggle.enabled?(:cavc_remand_granted_substitute_appellant)
        appellant_substitution = cavc_appeal.appellant_substitution
        if appellant_substitution.blank?
          create_appellant_substitution_and_cavc_remand_appellant_substitution(cavc_appeal, cavc_remand)
        else
          appellant_substitution.cavc_remand_appeal_substitution = true
          update_appellant_substitution_and_cavc_remand_appellant_substitution(cavc_appeal, cavc_remand,
                                                                               appellant_substitution)
        end
      end
    end

    render json: {
      cavc_remand: WorkQueue::CavcRemandSerializer.new(cavc_remand).serializable_hash[:data][:attributes],
      cavc_appeal: cavc_appeal,
      updated_appeal_attributes: updated_appeal_attributes(cavc_appeal)
    }, status: :ok
  end
  # rubocop:enable Metrics/MethodLength

  private

  def create_appellant_substitution_and_cavc_remand_appellant_substitution(cavc_appeal, new_cavc_remand)
    if params[:participant_id].present? && cavc_appeal
      cancel_unselected_tasks(cavc_appeal, current_user)
      appellant_substitution = create_appellant_substitution_and_history(cavc_appeal)
    end
    CavcRemandsAppellantSubstitution.create(
      cavc_remand_appellant_substitution_params.merge!(
        cavc_remand_id: new_cavc_remand.id,
        substitute_participant_id: params[:participant_id],
        appellant_substitution_id: appellant_substitution&.id
      )
    )
  end

  def create_appellant_substitution_and_history(cavc_appeal)
    appellant_substitution = AppellantSubstitution.create(
      appellant_substitution_params.merge!(created_by_id: current_user.id,
                                           source_appeal_id: source_appeal.id,
                                           target_appeal_id: cavc_appeal.id,
                                           claimant_type: "DependentClaimant",
                                           cavc_remand_appeal_substitution: true)
    )
    appellant_substitution.histories.create!(
      substitution_date: params[:substitution_date],
      original_appellant_veteran_participant_id: source_appeal.veteran.participant_id,
      current_appellant_substitute_participant_id: appellant_substitution.substitute_participant_id,
      created_by_id: current_user.id
    )
    appellant_substitution
  end

  def update_appellant_substitution_and_cavc_remand_appellant_substitution(cavc_appeal,
                                                                           new_cavc_remand,
                                                                           appellant_substitution)
    if params[:is_appellant_substituted] == "true"
      update_appellant_substitution_and_create_history(cavc_appeal, appellant_substitution)
    else
      original_appellant_substitute_participant_id = appellant_substitution.substitute_participant_id
      cancel_unselected_tasks(appellant_substitution.target_appeal, appellant_substitution.created_by)
      appellant_substitution.update(appellant_substitution_params(Date.current, cavc_appeal.veteran.participant_id))
      cavc_appeal.update(veteran_is_not_claimant: nil)
      appellant_substitution.histories.create(
        created_by_id: current_user.id,
        original_appellant_substitute_participant_id: original_appellant_substitute_participant_id,
        current_appellant_veteran_participant_id: cavc_appeal.veteran.participant_id
      )
    end
    remands_substitution_params = cavc_remand_appellant_substitution_params.except(:created_by_id)
    remands_substitution_params[:substitute_participant_id] = params[:participant_id]
    new_cavc_remand.cavc_remands_appellant_substitution.update(remands_substitution_params)
  end

  def appellant_substitution_params(substitution_date = params[:substitution_date],
                                    substitute_participant_id = params[:participant_id])
    params.permit(EDIT_CAVC_APPELLANT_SUBSTITUTION_PARAMS).merge!(
      substitution_date: substitution_date,
      substitute_participant_id: substitute_participant_id,
      skip_cancel_tasks: true
    )
  end

  # rubocop:disable Metrics/AbcSize
  def update_appellant_substitution_and_create_history(cavc_appeal, appellant_substitution)
    cancel_unselected_tasks(appellant_substitution.target_appeal, appellant_substitution.created_by)
    history_params = {}
    if appellant_substitution.substitution_date != params[:substitution_date].to_date
      history_params[:substitution_date] = params[:substitution_date]
    end
    if appellant_substitution.substitute_participant_id == cavc_appeal.veteran.participant_id
      history_params[:original_appellant_veteran_participant_id] = appellant_substitution.substitute_participant_id
      history_params[:current_appellant_substitute_participant_id] = params[:participant_id]
      cavc_appeal.update(veteran_is_not_claimant: true)
    elsif appellant_substitution.substitute_participant_id != params[:participant_id]
      history_params[:original_appellant_substitute_participant_id] = appellant_substitution.substitute_participant_id
      history_params[:current_appellant_substitute_participant_id] = params[:participant_id]
    end
    appellant_substitution.update(appellant_substitution_params)
    if history_params.present?
      appellant_substitution.histories.create(history_params.merge(created_by_id: current_user.id))
    end
  end
  # rubocop:enable Metrics/AbcSize

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
    params.permit(CAVC_APPELLANT_SUBSTITUTION_PARAMS)
  end

  def required_params_by_decisiontype_and_subtype
    case params["cavc_decision_type"]
    when Constants.CAVC_DECISION_TYPES.remand
      case params["remand_subtype"]
      when Constants.CAVC_REMAND_SUBTYPES.mdr
        REMAND_REQUIRED_PARAMS + MDR_REQUIRED_PARAMS
      else
        REMAND_REQUIRED_PARAMS + JMR_JMPR_REQUIRED_PARAMS
      end
    when Constants.CAVC_DECISION_TYPES.straight_reversal, Constants.CAVC_DECISION_TYPES.death_dismissal
      REMAND_REQUIRED_PARAMS
    when Constants.CAVC_DECISION_TYPES.other_dismissal, Constants.CAVC_DECISION_TYPES.affirmed,
      Constants.CAVC_DECISION_TYPES.settlement
      REMAND_REQUIRED_PARAMS
    else
      REMAND_REQUIRED_PARAMS
    end
  end

  def updated_appeal_attributes(cavc_appeal)
    return {} unless FeatureToggle.enabled?(:cavc_remand_granted_substitute_appellant)

    if cavc_appeal.reload.appellant_substitution
      appellant_substitution_data = WorkQueue::AppellantSubstitutionSerializer.new(cavc_appeal.appellant_substitution)
        .serializable_hash[:data][:attributes]
    end

    {
      appellant_substitution: appellant_substitution_data,
      appellant_is_not_veteran: cavc_appeal.appellant_is_not_veteran,
      appellant_full_name: cavc_appeal.claimant&.name,
      appellant_address: cavc_appeal.claimant&.address,
      appellant_relationship: cavc_appeal.appellant_relationship,
      appellant_type: cavc_appeal.claimant&.type
    }
  end

  def cancel_unselected_tasks(target_appeal, created_by)
    return if params[:cancelled_task_ids].blank? || params[:cancelled_task_ids].empty?

    task_ids = { cancelled: params[:cancelled_task_ids] }
    SameAppealSubstitutionTasksFactory.new(target_appeal,
                                           task_ids,
                                           created_by,
                                           {}).cancel_unselected_tasks
  end
end
