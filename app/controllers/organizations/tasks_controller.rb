# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  # This route might change to /queue/config with a later request to /tasks?page=1&tab=unassigned for instance.
  def index
    tasks = GenericQueue.new(user: organization).tasks

    # Temporarily limit hearings-management tasks to AOD tasks, because currently no tasks are loading
    if organization.url == "hearings-management"
      tasks = tasks.select { |task| task.appeal.is_a?(Appeal) || task.appeal.aod }
    end

    render json: {
      organization_name: organization.name,
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Representative),
      queue_config: queue_config.to_hash_for_user(current_user)
    }
  end

  # Endpoint for returning some subset of tasks.
  def tasks
    # Let's start with a single page (say, 25), unfiltered, for the unassigned tab.
    # - What bucket of tasks are we drawing from (unassigned)
    # - What offset (none)
    # /tasks?tab=unassigned
    params = {
      # Do we want to assume some default tab if no tab is passed?
      tab: "unassigned"
      # Assume first page if none passed
      # Assume no filters/sorting if none passed
    }

    # TODO: page(1) is just a placeholder for whichever pagination library we end up using.
    queue_config.tasks_for_tab(params[:tab]).page(1)
  end

  private

  def queue_config
    QueueConfig.new(organization: organization)
  end

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: organization.ama_task_serializer
    ).call
  end
end
