class AmaAppealsController < ApplicationController
  before_action :verify_ama_access

  def index
    appeals = Appeal.all
    render json: {
      tasks: [],
      appeals: json_appeals(appeals)
    }
  end

  private

  def verify_ama_access
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:queue_ama_appeals)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
