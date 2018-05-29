class BeaamAppealsController < ApplicationController
  before_action :verify_beaam_access

  def index
    appeals = Appeal.all
    render json: {
      appeals: json_appeals(appeals),
      tasks: []
    }
  end

  private

  def verify_beaam_access
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:queue_beaam_appeals)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
