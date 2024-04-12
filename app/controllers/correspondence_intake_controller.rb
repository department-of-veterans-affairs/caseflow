# frozen_string_literal: true

class CorrespondenceIntakeController < CorrespondenceController
  def intake
    # If correspondence intake was started, json data from the database will
    # be loaded into the page when user returns to intake
    @redux_store ||= CorrespondenceIntake.find_by(user: current_user,
                                                  correspondence: current_correspondence)&.redux_store

    respond_to do |format|
      format.html { return render "correspondence/intake" }
      format.json do
        render json: {
          currentCorrespondence: current_correspondence,
          correspondence: correspondence_load,
          veteranInformation: veteran_information
        }
      end
    end
  end

  def current_step
    intake = CorrespondenceIntake.find_by(user: current_user, correspondence: current_correspondence) ||
             CorrespondenceIntake.new(user: current_user, correspondence: current_correspondence)

    intake.update(
      current_step: params[:current_step],
      redux_store: params[:redux_store]
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
      intake_appeal_update_tasks
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
      intake_task = Task.where("appeal_id = ? and appeal_type = 'Correspondence' and type = 'CorrespondenceIntakeTask'",
                               current_correspondence.id).first
      intake_task.update!(status: "cancelled")
      ReviewPackageTask.create!(
        assigned_to: User.find(current_correspondence.assigned_by_id),
        assigned_to_id: current_correspondence.assigned_by_id,
        status: "assigned",
        appeal_id: current_correspondence.id,
        appeal_type: "Correspondence"
      )
      render json: {}, status: :ok
    rescue StandardError
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  private

  def correspondence_load
    Correspondence.where(veteran_id: veteran_by_correspondence.id).where.not(uuid: params[:correspondence_uuid])
  end
end
