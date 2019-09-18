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

    # Temporarily limit hearings-management tasks to AOD tasks, because currently no tasks are loading
    if organization.url == "hearings-management"
      tasks = GenericQueue.new(user: organization, limit: 1000).tasks
      Rails.logger.debug("starting AOD filter")
      tasks.select { |task| task.appeal.is_a?(Appeal) || task.appeal.aod }
    else
      GenericQueue.new(user: organization, limit: 1000).tasks
    end
  end

  def queue_config
    QueueConfig.new(assignee: organization).to_hash_for_user(current_user)
  end

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    Rails.logger.debug("starting AppealRepository.eager_load_legacy_appeals_for_tasks")
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    Rails.logger.debug("starting AmaAndLegacyTaskSerializer")
    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: organization.ama_task_serializer
    ).call
  end
end
