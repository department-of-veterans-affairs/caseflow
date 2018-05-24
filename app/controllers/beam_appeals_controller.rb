class BeamAppealsController < ApplicationController
  before_action :verify_beam_access

  def index
    appeals = Appeal.all
    render json: {
      tasks: json_tasks(generate_tasks(appeals)),
      appeals: json_appeals(appeals)
    }
  end

  def generate_tasks(appeals)
    appeals.map do |appeal|
      Task.new(id: rand(10000), appeal_id: appeal.id)
    end
  end

  private

  def verify_beam_access
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:queue_beam_appeals)
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
