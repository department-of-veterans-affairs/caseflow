class BeamAppealsController < ApplicationController
  before_action :verify_beam_access

  def index
    appeals = Appeal.all
    render json: {
      tasks: [],
      appeals: json_appeals(appeals)
    }
  end

  private

  def verify_beam_access
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:queue_beam_appeals)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
