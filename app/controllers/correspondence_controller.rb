# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include CorrespondenceControllerConcern
  include RunAsyncable

  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts

  def auto_assign_correspondences
    batch = BatchAutoAssignmentAttempt.create!(
      user: current_user,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started
    )

    job_args = {
      current_user_id: current_user.id,
      batch_auto_assignment_attempt_id: batch.id
    }

    begin
      perform_later_or_now(AutoAssignCorrespondenceJob, job_args)
      render json: { batch_auto_assignment_attempt_id: batch&.id }, status: :ok
    rescue StandardError => error
      Rails.logger.error(error.full_message)
      render json: { success: false, error: error }
    end
  end

  # :reek:FeatureEnvy
  def auto_assign_status
    batch = BatchAutoAssignmentAttempt.includes(:individual_auto_assignment_attempts)
      .find_by!(user: current_user, id: corr_controller_params[:batch_auto_assignment_attempt_id])

    num_assigned = batch.individual_auto_assignment_attempts
      .where(status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed).count

    status_details = {
      error_message: batch.error_info,
      status: batch.status,
      number_assigned: num_assigned,
      number_attempted: batch.individual_auto_assignment_attempts.count
    }

    render json: status_details, status: :ok
  end

  private

  def corr_controller_params
    params.permit(:batch_auto_assignment_attempt_id)
  end

  def verify_correspondence_access
    return true if InboundOpsTeam.singleton.user_has_access?(current_user)

    redirect_to "/unauthorized"
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue) && verify_correspondence_access
      redirect_to "/under_construction"
    elsif !FeatureToggle.enabled?(:correspondence_queue) || !verify_correspondence_access
      redirect_to "/unauthorized"
    end
  end
end
