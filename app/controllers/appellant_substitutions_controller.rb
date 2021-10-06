# frozen_string_literal: true

# Controller to create a Appellant Substitution and a resulting new Appeal associated
# with a dispatched appeal.

class AppellantSubstitutionsController < ApplicationController
  before_action :validate_substitution_access

  REQUIRED_PARAMS = [
    :source_appeal_id,
    :substitution_date,
    :claimant_type,
    :substitute_participant_id,
    :created_by_id
  ].freeze

  PERMITTED_PARAMS = {
    poa_participant_id: nil,
    # blank or empty values for these params will fail the required validation, so put them here instead
    selected_task_ids: [],
    task_params: {}
  }.freeze

  def create
    new_substitution = AppellantSubstitution.create!(create_params)
    target_appeal = new_substitution.target_appeal.reload
    render json: { substitution: new_substitution, targetAppeal: target_appeal }, status: :created
  end

  private

  def source_appeal
    @source_appeal ||= Appeal.find_by_uuid(params[:source_appeal_id])
  end

  def validate_substitution_access
    unless ClerkOfTheBoard.singleton.user_has_access?(current_user)
      msg = "Only Clerk of the Board users can create Appellant Substitutions"
      fail Caseflow::Error::ActionForbiddenError, message: msg
    end
  end

  def create_params
    params.merge!(created_by_id: current_user.id, source_appeal_id: source_appeal.id)
    params.require(REQUIRED_PARAMS)
    params.permit(REQUIRED_PARAMS, PERMITTED_PARAMS)
  end
end
