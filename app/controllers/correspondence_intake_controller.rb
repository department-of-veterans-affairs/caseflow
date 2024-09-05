# frozen_string_literal: true

class CorrespondenceIntakeController < CorrespondenceController
  before_action :verify_correspondence_intake_access
  def intake
    # If correspondence intake was started, json data from the database will
    # be loaded into the page when user returns to intake
    @redux_store ||= CorrespondenceIntake.find_by(
      task: correspondence&.open_intake_task
    )&.redux_store
    @prior_mail = prior_mail.map do |correspondence|
      WorkQueue::CorrespondenceSerializer.new(correspondence).serializable_hash[:data][:attributes]
    end
    @correspondence = WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
      .merge(general_information)
  end

  def current_step
    intake = CorrespondenceIntake.find_by(task: correspondence&.open_intake_task) ||
             CorrespondenceIntake.new(task: correspondence&.open_intake_task)
    intake.update(
      current_step: corr_intake_params[:current_step],
      redux_store: redux_store
    )

    if intake.valid?
      intake.save!

      render(json: {}, status: :ok) && return
    else
      render(json: intake.errors.full_messages, status: :unprocessable_entity) && return
    end
  end

  def intake_update
    begin
      correspondence.cancel_task_tree_for_appeal_intake
      upload_documents_to_claim_evidence if FeatureToggle.enabled?(:ce_api_demo_toggle)
      render json: { correspondence: correspondence }
    rescue StandardError => error
      Rails.logger.error(error.to_s)
      Raven.capture_exception(error)
      render json: {}, status: :bad_request
    end
  end

  def process_intake
    if correspondence_intake_processor.process_intake(params, current_user)
      set_flash_intake_success_message
      render json: {}, status: :created
    else
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  def cancel_intake
    begin
      # find the correspondence intake task even if it isn't assigned to the user
      intake_task = CorrespondenceIntakeTask.open.find_by(appeal_id: correspondence.id)
      intake_task.update!(status: Constants.TASK_STATUSES.cancelled)
      ReviewPackageTask.find_or_create_by!(
        parent_id: intake_task.parent_id,
        assigned_to: intake_task.assigned_to,
        status: Constants.TASK_STATUSES.assigned,
        appeal_id: correspondence.id,
        appeal_type: "Correspondence"
      )
      render json: {}, status: :ok
    rescue StandardError
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  private

  def corr_intake_params
    params.permit(:current_step, :correspondence_uuid)
  end

  def redux_store
    params.require(:redux_store)
  end

  def correspondence_uuid
    params.permit(:correspondence_uuid)[:correspondence_uuid]
  end

  def prior_mail
    Correspondence.prior_mail(veteran_by_correspondence.id, corr_intake_params[:correspondence_uuid])
      .select { |corr| corr.status == "Completed" || corr.status == "Pending" }
  end

  def verify_correspondence_intake_access
    active_intake_task = CorrespondenceIntakeTask.open.find_by(appeal_id: correspondence.id)
    # route if no active task
    route_user unless active_intake_task && user_can_work_intake(active_intake_task)
  end

  # always allow supervisors and superusers to acccess intakes not assigned to them.
  def user_can_work_intake(task)
    (task.assigned_to == current_user) ||
      (current_user.inbound_ops_team_supervisor? || current_user.inbound_ops_team_superuser?)
  end

  # redirect if no access
  def route_user
    if current_user.inbound_ops_team_user?
      redirect_to "/queue/correspondence"
    elsif current_user.inbound_ops_team_superuser? || current_user.inbound_ops_team_supervisor?
      redirect_to "/queue/correspondence/team"
    else
      redirect_to "/unauthorized"
    end
  end
end
