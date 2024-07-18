# frozen_string_literal: true

class CorrespondenceReviewPackageController < CorrespondenceController
  def review_package
    set_instance_variables

    respond_to do |format|
      format.html
      format.json { render json: build_json_response, status: :ok }
    end
  end

  def update
    unless update_veteran_on_correspondence
      return render(json: { error: "Please enter a valid Veteran ID" }, status: :unprocessable_entity)
    end

    if update_open_review_package_tasks
      # return the new JSON response to update the frontend with changes
      render json: { correspondence: serialized_correspondence, status: :ok }
    else
      render json: { error: "Failed to update tasks" }, status: :internal_server_error
    end
  end

  def update_cmp
    correspondence.update(
      va_date_of_receipt: params["VADORDate"].in_time_zone
    )

    correspondence.tasks.map do |task|
      if task.type == "ReviewPackageTask"
        task.status = "in_progress"
        task.save
      end
    end
    render json: { status: 200, correspondence: correspondence }
  end

  def document_type_correspondence
    data = vbms_document_types
    render json: { data: data }
  end

  def pdf
    # Hard-coding Document access until CorrespondenceDocuments are uploaded to S3Bucket
    document = Document.limit(200)[pdf_params[:pdf_id].to_i]

    document_disposition = "inline"
    if pdf_params[:download]
      document_disposition = "attachment; filename='#{pdf_params[:type]}-#{pdf_params[:id]}.pdf'"
    end

    # The line below enables document caching for a month.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: document_disposition
    )
  end

  private

  def set_instance_variables
    @inbound_ops_team_users = User.inbound_ops_team_users.select(:css_id).pluck(:css_id)
    @correspondence_types = CorrespondenceType.all
    @has_efolder_failed_task = correspondence_has_efolder_failed_task?
    @correspondence = serialized_correspondence
  end

  def serialized_correspondence
    WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
      .merge(general_information)
  end

  def build_json_response
    {
      correspondence: @correspondence,
      general_information: general_information,
      user_can_edit_vador: current_user.inbound_ops_team_supervisor?,
      corres_docs: @correspondence[:correspondenceDocuments],
      taskInstructions: task_instructions
    }
  end

  def task_instructions
    CorrespondenceTask.package_action_tasks.open
      .find_by(appeal_id: @correspondence[:id])&.instructions || ""
  end

  def correspondence_has_efolder_failed_task?
    correspondence.tasks.active.where(type: EfolderUploadFailedTask.name).exists?
  end

  def correspondence_params
    params.require(:correspondence).permit(:correspondence, :notes, :correspondence_type_id, :va_date_of_receipt)
      .merge(params.require(:veteran).permit(:file_number, :first_name, :last_name))
  end

  def pdf_params
    params.permit(pdf: [:pdf_id, :type, :id, :download])
  end

  def update_veteran_on_correspondence
    veteran = Veteran.find_by(file_number: correspondence_params[:file_number])
    if veteran
      correspondence.update!(
        veteran_id: veteran.id,
        notes: correspondence_params[:notes],
        correspondence_type_id: correspondence_params[:correspondence_type_id],
        va_date_of_receipt: correspondence_params[:va_date_of_receipt]
      )
      true
    else
      false
    end
  end

  # :reek:FeatureEnvy
  def update_open_review_package_tasks
    begin
      ActiveRecord::Base.transaction do
        correspondence.tasks.open.where(type: ReviewPackageTask.name).find_each do |task|
          task.update!(status: Constants.TASK_STATUSES.in_progress)
        end
      end
      true
    rescue ActiveRecord::RecordInvalid => error
      Rails.logger.error "Failed to update task due to validation error: #{error.message}"
      false
    rescue StandardError => error
      Rails.logger.error "Failed to update tasks due to an unexpected error: #{error.message}"
      false
    end
  end

  # :reek:FeatureEnvy
  def vbms_document_types
    begin
      data = ExternalApi::ClaimEvidenceService.document_types
    rescue StandardError => error
      Rails.logger.error(error.full_message)
      data ||= demo_data
    end
    data.map { |document_type| { id: document_type["id"], name: document_type["description"] } }
  end

  def demo_data
    json_file_path = "./lib/fakes/constants/VBMS_DOC_TYPES.json"
    JSON.parse(File.read(json_file_path))
  end
end
