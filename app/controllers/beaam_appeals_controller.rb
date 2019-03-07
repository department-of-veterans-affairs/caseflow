# frozen_string_literal: true

class BeaamAppealsController < ApplicationController
  before_action :verify_beaam_access

  def index
    appeals = Appeal.all
    render json: {
      tasks: json_appeals(appeals)
    }
  end

  private

  def verify_beaam_access
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:queue_beaam_appeals, user: current_user)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::BeaamSerializer
    ).as_json
  end
end
