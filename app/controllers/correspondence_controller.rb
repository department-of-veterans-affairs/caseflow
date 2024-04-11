# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts
  before_action :veteran_information

  def correspondence_cases
    respond_to do |format|
      format.html { "correspondence_cases" }
      format.json do
        render json: { vetCorrespondences: veterans_with_correspondences }
      end
    end
  end

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def veteran_information
    @veteran_information ||= veteran_by_correspondence
  end

  private

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
end
