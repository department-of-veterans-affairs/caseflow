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

  def show
    @correspondence = Correspondence.find(params[:id])
    render json: { correspondence: @correspondence, package_document_type: @correspondence.package_document_type }
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
    @all_correspondence = Correspondence.where(veteran_id: vet.id)
  end

  def correspondence_by_uuid
    Correspondence.find_by(uuid: params[:correspondence_uuid])
  end

  def veteran_by_correspondence
    Veteran.find(@correspondence.veteran_id)
  end

  def veterans_with_correspondences
    serialized_veteran_array = []
    all_ids_with_corrs = Correspondence.select(:veteran_id).map(&:veteran_id).uniq

    all_ids_with_corrs.each do |id|
      veteran = Veteran.find(id)
      correspondence = Correspondence.find_by(veteran_id: id)
      serialized_veteran_array << vet_info_serializer(veteran, correspondence)
    end

    serialized_veteran_array
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
