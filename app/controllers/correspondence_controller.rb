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

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def show
    render json: { correspondence: correspondence, package_document_type: correspondence&.package_document_type }
  end

  private

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
    @all_correspondence = Correspondence.where(veteran_id: veteran_by_correspondence&.id)
  end

  def veteran_by_correspondence
    return @veteran_by_correspondence if @veteran_by_correspondence.present?

    @veteran_by_correspondence = Veteran.find(correspondence&.veteran_id)

    @veteran_by_correspondence
  end

end
