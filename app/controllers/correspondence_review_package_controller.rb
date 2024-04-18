# frozen_string_literal: true

class CorrespondenceReviewPackageController < CorrespondenceController
  def review_package
    @mail_team_users = User.mail_team_users.select(:css_id).pluck(:css_id)
  end

  def package_documents
    packages = PackageDocumentType.all
    render json: { package_document_types: packages }
  end

  def show
    corres_docs = correspondence.correspondence_documents
    task_instructions = CorrespondenceTask.package_action_tasks.open
      .find_by(appeal_id: correspondence.id)&.instructions || ""
    response_json = {
      correspondence: correspondence,
      package_document_type: correspondence&.package_document_type,
      general_information: general_information,
      user_can_edit_vador: current_user.mail_supervisor?,
      correspondence_documents: corres_docs.map do |doc|
        WorkQueue::CorrespondenceDocumentSerializer.new(doc).serializable_hash[:data][:attributes]
      end,
      efolder_upload_failed_before: EfolderUploadFailedTask.where(
        appeal_id: correspondence.id, type: "EfolderUploadFailedTask"
      ),
      taskInstructions: task_instructions
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
      va_date_of_receipt: params["VADORDate"].in_time_zone,
      package_document_type_id: params["packageDocument"]["value"].to_i
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
    document = Document.limit(200)[params[:pdf_id].to_i]

    document_disposition = "inline"
    if params[:download]
      document_disposition = "attachment; filename='#{params[:type]}-#{params[:id]}.pdf'"
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

  def update_veteran_on_correspondence
    veteran = Veteran.find_by(file_number: veteran_params["file_number"])
    veteran && correspondence.update(
      correspondence_params.merge(
        veteran_id: veteran.id,
        updated_by_id: RequestStore.store[:current_user].id
      )
    )
  end

  def update_open_review_package_tasks
    correspondence.tasks.open.where(type: ReviewPackageTask.name).each do |task|
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
    json_file_path = "vbms doc types.json"
    JSON.parse(File.read(json_file_path))
  end
end
