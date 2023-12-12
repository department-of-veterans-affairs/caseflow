# frozen_string_literal: true

class CorrespondenceController < ApplicationController
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts

  def intake
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
    response_json = {
      correspondence: correspondence,
      package_document_type: correspondence&.package_document_type,
      general_information: general_information,
      correspondence_documents: corres_docs.map do |doc|
        WorkQueue::CorrespondenceDocumentSerializer.new(doc).serializable_hash[:data][:attributes]
      end
    }
    render({ json: response_json }, status: :ok)
  end

  def update
    if veteran_by_correspondence.update(veteran_params) && correspondence.update(
      correspondence_params.merge(updated_by_id: RequestStore.store[:current_user].id)
    )
      render json: { status: :ok }
    else
      render json: { error: "Failed to update records" }, status: :unprocessable_entity
    end
  end

  def update_cmp
    correspondence.update(
      va_date_of_receipt: params["VADORDate"].in_time_zone,
      package_document_type_id: params["packageDocument"]["value"].to_i
    )
    render json: { status: 200, correspondence: correspondence }
  end

  # :reek:UtilityFunction
  def vbms_document_types
    data = ExternalApi::ClaimEvidenceService.document_types
    data["documentTypes"].map { |document_type| { id: document_type["id"], name: document_type["name"] } }
  end

  def pdf
    document = Document.find(params[:pdf_id])

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
    correspondence_id = Correspondence.find_by(uuid: params[:correspondence_uuid])&.id
    ActiveRecord::Base.transaction do
      begin
        create_correspondence_relations(correspondence_id)
        add_tasks_to_related_appeals(correspondence_id)
      rescue ActiveRecord::RecordInvalid
        render json: { error: "Failed to update records" }, status: :bad_request
        raise ActiveRecord::Rollback
      rescue ActiveRecord::RecordNotUnique
        render json: { error: "Failed to update records" }, status: :bad_request
        raise ActiveRecord::Rollback
      else
        set_flash_intake_success_message
        render json: {}, status: :created
      end
    end
  end

  private

  def set_flash_intake_success_message
    # intake error message is handled in client/app/queue/correspondence/intake/components/CorrespondenceIntake.jsx
    vet = veteran_by_correspondence
    flash[:correspondence_intake_success] = [
      "You have successfully submitted a correspondence record for #{vet.name}(#{vet.file_number})",
      "The mail package has been uploaded to the Veteran's eFolder as well."
    ]
  end

  def create_correspondence_relations(correspondence_id)
    params[:related_correspondence_uuids]&.map do |uuid|
      CorrespondenceRelation.create!(
        correspondence_id: correspondence_id,
        related_correspondence_id: Correspondence.find_by(uuid: uuid)&.id
      )
    end
  end

  def add_tasks_to_related_appeals(correspondence_id)
    params[:tasks_related_to_appeal]&.map do |data|
      appeal = Appeal.find(data[:appeal_id])
      CorrespondencesAppeal.find_or_create_by(correspondence_id: correspondence_id, appeal_id: appeal.id)
      # Remove this unless block when HearingWithdrawalMailTask is implemented
      unless data[:klass] == "HearingWithdrawalMailTask"
        data[:klass].constantize.create_from_params(
          {
            appeal: appeal,
            parent_id: appeal.root_task&.id,
            assigned_to: data[:assigned_to].constantize.singleton,
            instructions: data[:content]
          }, current_user
        )
      end
    end
  end

  def general_information
    vet = veteran_by_correspondence
    {
      notes: correspondence.notes,
      file_number: vet.file_number,
      veteran_name: vet.name,
      correspondence_type_id: correspondence.correspondence_type_id,
      correspondence_types: CorrespondenceType.all
    }
  end

  def correspondence_params
    params.require(:correspondence).permit(:notes, :correspondence_type_id)
  end

  def veteran_params
    params.require(:veteran).permit(:file_number)
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue)
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
    @veteran_by_correspondence ||= Veteran.find(correspondence&.veteran_id)
  end

  def veterans_with_correspondences
    veterans = Veteran.includes(:correspondences).where(correspondences: { id: Correspondence.select(:id) })
    veterans.map { |veteran| vet_info_serializer(veteran, veteran.correspondences.first) }
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

  def auto_texts
    @auto_texts ||= AutoText.all.pluck(:name)
  end
end
