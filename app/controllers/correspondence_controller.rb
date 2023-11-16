# frozen_string_literal: true

class CorrespondenceController < ApplicationController
  before_action :verify_feature_toggle

  def intake
    respond_to do |format|
      format.html { return render "correspondence/intake" }
      format.json do
        render json: {
          correspondence: correspondence_load
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

  def package_documents
    packages = PackageDocumentType.all
    render json: { package_document_types: packages }
  end

  def show
    @correspondence = Correspondence.find(params[:id])
    render json: { correspondence: @correspondence, package_document_type: @correspondence.package_document_type }
  end

  def update_cmp
    @correspondence = Correspondence.find_by(uuid: params[:correspondence_uuid])
    @correspondence.update(va_date_of_receipt: params["VADORDate"].in_time_zone,
                           package_document_type_id: params["packageDocument"]["value"].to_i)
    render json: { status: 200, correspondence: @correspondence }
  end

  private

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue)
      redirect_to "/unauthorized"
    end
  end

  def correspondence_load
    @correspondence ||= correspondence_by_uuid
    vet = veteran_by_correspondence
    @all_correspondence = Correspondence.where(veteran_id: vet.id).where.not(uuid: params[:correspondence_uuid])
  end

  def correspondence_by_uuid
    Correspondence.find_by(uuid: params[:correspondence_uuid])
  end

  def veteran_by_correspondence
    Veteran.find(@correspondence.veteran_id)
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
end
