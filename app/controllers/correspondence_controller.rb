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
