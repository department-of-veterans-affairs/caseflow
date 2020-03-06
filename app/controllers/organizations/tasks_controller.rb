# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    render json: {
      organization_name: organization.name,
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Representative),
      queue_config: queue_config
    }
  end

  private

  def tasks
    return [] if queue_config[:use_task_pages_api]

    Rails.logger.debug("starting GenericQueue tasks")
    GenericQueue.new(user: organization, limit: 1000).tasks
  end

  def queue_config
    QueueConfig.new(assignee: organization).to_hash
  end

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    AmaAndLegacyTaskSerializer.create_and_preload_legacy_appeals(
      tasks: tasks,
      params: { user: current_user },
      ama_serializer: organization.ama_task_serializer
    ).call
  end
end
