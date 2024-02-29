# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include RunAsyncable

  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts
  before_action :veteran_information

  def intake
    respond_to do |format|
      format.html { return render "correspondence/intake" }
      format.json do
        render json: {
          currentCorrespondence: current_correspondence,
          correspondence: correspondence_load,
          veteranInformation: veteran_information,
          responseLetters: 0
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

  def correspondence_cases
    respond_to do |format|
      format.html { "correspondence_cases" }
      format.json do
        render json: { vetCorrespondences: veterans_with_correspondences }
      end
    end
  end

  def review_package
    render "correspondence/review_package"
  end

  def intake_update
    begin
      intake_appeal_update_tasks
      if FeatureToggle.enabled?(:ce_api_demo_toggle)
        upload_documents_to_claim_evidence
      end
      render json: { correspondence: correspondence }
    rescue StandardError => error
      Rails.logger.error(error.to_s)
      Raven.capture_exception(error)
      render json: {}, status: :bad_request
    end
  end

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def package_documents
    packages = PackageDocumentType.all
    render json: { package_document_types: packages }
  end

  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def veteran_information
    @veteran_information ||= veteran_by_correspondence
  end

  def show
    corres_docs = correspondence.correspondence_documents
    reason_remove = if RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name).nil?
                      ""
                    else
                      RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name).instructions
                    end
    response_json = {
      correspondence: correspondence,
      package_document_type: correspondence&.package_document_type,
      general_information: general_information,
      user_can_edit_vador: InboundOpsTeam.singleton.user_has_access?(current_user),
      correspondence_documents: corres_docs.map do |doc|
        WorkQueue::CorrespondenceDocumentSerializer.new(doc).serializable_hash[:data][:attributes]
      end,
      efolder_upload_failed_before: EfolderUploadFailedTask.where(
        appeal_id: correspondence.id, type: "EfolderUploadFailedTask"
      ),
      reasonForRemovePackage: reason_remove
    }
    render({ json: response_json }, status: :ok)
  end

  def update
    veteran = Veteran.find_by(file_number: veteran_params["file_number"])
    if veteran && correspondence.update(
      correspondence_params.merge(
        veteran_id: veteran.id,
        updated_by_id: RequestStore.store[:current_user].id
      )
    )
      correspondence.tasks.map do |task|
        if task.type == "ReviewPackageTask"
          task.status = "in_progress"
          task.save
        end
      end
      render json: { status: :ok }
    else
      render json: { error: "Please enter a valid Veteran ID" }, status: :unprocessable_entity
    end
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

  def process_intake
    if correspondence_intake_processor.process_intake(params, current_user)
      set_flash_intake_success_message
      render json: {}, status: :created
    else
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  def auto_assign_correspondences
    batch = existing_batch_auto_assignment_attempt

    if batch.nil?
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
      ensure
        render json: { batch_auto_assignment_attempt_id: batch.id }, status: :ok
      end
    else
      render json: { batch_auto_assignment_attempt_id: batch.id }, status: :ok
    end
  end

  def auto_assign_status
    batch = BatchAutoAssignmentAttempt.find_by!(user: current_user, id: params["batch_auto_assignment_attempt_id"])
    status_details = {
      error_message: batch.error_info,
      status: batch.status,
      number_assigned: batch.num_packages_assigned
    }
    render json: status_details, status: :ok
  end

  private

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

  def set_flash_intake_success_message
    # intake error message is handled in client/app/queue/correspondence/intake/components/CorrespondenceIntake.jsx
    vet = veteran_by_correspondence
    flash[:correspondence_intake_success] = [
      "You have successfully submitted a correspondence record for #{vet.name}(#{vet.file_number})",
      "The mail package has been uploaded to the Veteran's eFolder as well."
    ]
  end

  def verify_correspondence_access
    return true if InboundOpsTeam.singleton.user_has_access?(current_user) ||
                   MailTeam.singleton.user_has_access?(current_user)

    redirect_to "/unauthorized"
  end

  def general_information
    vet = veteran_by_correspondence
    {
      notes: correspondence.notes,
      file_number: vet.file_number,
      veteran_name: vet.name,
      correspondence_type_id: correspondence.correspondence_type_id,
      correspondence_types: CorrespondenceType.all,
      correspondence_tasks: correspondence.tasks.map do |task|
        WorkQueue::CorrespondenceTaskSerializer.new(task).serializable_hash[:data][:attributes]
      end
    }
  end

  def correspondence_params
    params.require(:correspondence).permit(:notes, :correspondence_type_id)
  end

  def veteran_params
    params.require(:veteran).permit(:file_number)
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue) && verify_correspondence_access
      redirect_to "/under_construction"
    elsif !FeatureToggle.enabled?(:correspondence_queue) || !verify_correspondence_access
      redirect_to "/unauthorized"
    end
  end

  def correspondence
    return @correspondence if @correspondence.present?

    if params[:id].present?
      @correspondence = Correspondence.find(params[:id])
    elsif params[:correspondence_uuid].present?
      @correspondence = Correspondence.find_by(uuid: params[:correspondence_uuid])
    end

    @correspondence
  end

  def correspondence_load
    Correspondence.where(veteran_id: veteran_by_correspondence.id).where.not(uuid: params[:correspondence_uuid])
  end

  def veteran_by_correspondence
    return nil if correspondence&.veteran_id.blank?

    @veteran_by_correspondence ||= Veteran.find_by(id: correspondence.veteran_id)
  end

  def veterans_with_correspondences
    veterans = Veteran.includes(:correspondences).where(correspondences: { id: Correspondence.select(:id) })
    veterans.map { |veteran| vet_info_serializer(veteran, veteran.correspondences.last) }
  end

  def auto_texts
    @auto_texts ||= AutoText.all.pluck(:name)
  end

  def vet_info_serializer(veteran, correspondence)
    {
      firstName: veteran.first_name,
      lastName: veteran.last_name,
      fileNumber: veteran.file_number,
      cmPacketNumber: correspondence.cmp_packet_number,
      correspondenceUuid: correspondence.uuid,
      packageDocumentType: correspondence.correspondence_type_id
    }
  end

  def correspondence_intake_processor
    @correspondence_intake_processor ||= CorrespondenceIntakeProcessor.new
  end

  def correspondence_documents_efolder_uploader
    @correspondence_documents_efolder_uploader ||= CorrespondenceDocumentsEfolderUploader.new
  end

  # :reek:FeatureEnvy
  def intake_appeal_update_tasks
    tasks = Task.where("appeal_id = ? and appeal_type = ?", correspondence.id, "Correspondence")
    tasks.map do |task|
      if task.type == "ReviewPackageTask"
        task.instructions.push("An appeal intake was started because this Correspondence is a 10182")
        task.assigned_to_id = correspondence.assigned_by_id
        task.assigned_to = User.find(correspondence.assigned_by_id)
      end
      task.status = "cancelled"
      task.save
    end
  end

  def upload_documents_to_claim_evidence
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
    correspondence_documents_efolder_uploader.upload_documents_to_claim_evidence(correspondence, current_user, rpt)
  end

  def existing_batch_auto_assignment_attempt
    @existing_batch_auto_assignment_attempt ||= BatchAutoAssignmentAttempt.find_by(
      user: current_user,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started
    )
  end
end
