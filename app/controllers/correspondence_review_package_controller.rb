# frozen_string_literal: true

class CorrespondenceReviewPackageController < CorrespondenceController
  def review_package
    @inbound_ops_team_users = User.inbound_ops_team_users.select(:css_id).pluck(:css_id)
  end

  def show
    corres_docs = correspondence.correspondence_documents
    task_instructions = CorrespondenceTask.package_action_tasks.open
      .find_by(appeal_id: correspondence.id)&.instructions || ""
    response_json = {
      correspondence: correspondence,
      general_information: general_information,
      user_can_edit_vador: current_user.inbound_ops_team_supervisor?,
      correspondence_documents: corres_docs.map do |doc|
        WorkQueue::CorrespondenceDocumentSerializer.new(doc).serializable_hash[:data][:attributes]
      end,
      efolder_upload_failed_before: EfolderUploadFailedTask.where(
        appeal_id: correspondence.id, type: "EfolderUploadFailedTask"
      ),
      taskInstructions: task_instructions,
      display_intake_appeal: display_intake_appeal
    }
    render({ json: response_json }, status: :ok)
  end

  def update
    unless update_veteran_on_correspondence
      return render(json: { error: "Please enter a valid Veteran ID" }, status: :unprocessable_entity)
    end

    update_open_review_package_tasks ? render(json: { status: :ok }) : render(json: { status: 500 })
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
    document = Document.limit(200)[correspondence_params[:pdf_id].to_i]

    document_disposition = "inline"
    if correspondence_params[:download]
      document_disposition = "attachment; filename='#{correspondence_params[:type]}-#{correspondence_params[:id]}.pdf'"
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

  def correspondence_params
    params.require(:correspondence).permit(:notes, :correspondence_type_id, :va_date_of_receipt)
      .merge(params.require(:veteran).permit(:file_number))
      .merge(params.permit(:pdf_id, :type, :id, :download))
  end

  def display_intake_appeal
    !(current_user.inbound_ops_team_supervisor? || current_user.inbound_ops_team_superuser?)
  end

  def update_veteran_on_correspondence
    veteran = Veteran.find_by(file_number: correspondence_params["file_number"])
    veteran && correspondence.update!(
      veteran_id: veteran.id,
      notes: correspondence_params[:notes],
      correspondence_type_id: correspondence_params[:correspondence_type_id]
    )
  end

  def update_open_review_package_tasks
    correspondence.tasks.open.where(type: ReviewPackageTask.name).find_each do |task|
      task.update(status: Constants.TASK_STATUSES.in_progress)
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
