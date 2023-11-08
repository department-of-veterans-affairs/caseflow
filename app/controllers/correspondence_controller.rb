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
    render "correspondence_cases"
  end

  def review_package
    render "correspondence/review_package"
  end

  def show
    @correspondence = Correspondence.find(params[:id])
    render json: { correspondence: @correspondence, package_document_type: @correspondence.package_document_type, correspondence_documents: @correspondence.correspondence_documents }
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

end
