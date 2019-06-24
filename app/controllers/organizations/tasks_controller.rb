# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  # This route might change to /queue/config with a later request to /tasks?page=1&tab=unassigned for instance.
  def index
    render json: {
      organization_name: organization.name,
      # TODO: Return a new attribute of this hash called something like "use_backend_paging"
      # and return an empty set of tasks if that is true (we will populate them with API calls).
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Representative),
      queue_config: queue_config
    }
  end

  # Endpoint for returning some subset of tasks.
  # TODO: Define a route to this method (maybe a different controller entirely?)
  def paged_tasks
    # Let's start with a single page (say, 15), unfiltered, for the unassigned tab.
    # - What bucket of tasks are we drawing from (unassigned)
    # - What offset (none)
    # /organizations/{org.url}/tasks?
    #   tab=on_hold&
    #   sort_by=case_details_link&
    #   order=desc&
    #   filter[]=col%3Ddocket_type%26val%3Dlegacy&
    #   filter[]=col%3Dtask_action%26val%3Dtranslation&
    #   page=3
    #
    # params = <ActionController::Parameters {
    #   "tab"=>"on_hold",
    #   "sort_by"=>"case_details_link",
    #   "order"=>"desc",
    #   "filter"=>["col=docket_type&val=legacy", "col=task_action&val=translation"],
    #   "page"=>"3"
    # }>

    # TaskPage.new(
    #   assignee: organization,
    #   tab_name: params[:tab],
    #   filters: params[:filter],
    #   sort_order: params[:order],
    #   sort_by: params[:sort_by],
    #   page: params[:page]
    # ).paged_tasks
  end

  private

  def tasks
    Rails.logger.debug("starting GenericQueue tasks")

    # Temporarily limit hearings-management tasks to AOD tasks, because currently no tasks are loading
    if organization.url == "hearings-management"
      tasks = GenericQueue.new(user: organization, limit: 200).tasks
      Rails.logger.debug("starting AOD filter")
      tasks.select { |task| task.appeal.is_a?(Appeal) || task.appeal.aod }
    else
      GenericQueue.new(user: organization, limit: 200).tasks
    end
  end

  def queue_config
    QueueConfig.new(organization: organization).to_hash_for_user(current_user)
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
