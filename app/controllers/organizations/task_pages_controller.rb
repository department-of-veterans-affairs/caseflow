# frozen_string_literal: true

class Organizations::TaskPagesController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    # TODO: Raise a ruckus if required parameters are not included.
    tasks = TaskPage.new(
      assignee: organization,
      tab_name: params[:tab],
      page: params[:page]
    ).paged_tasks

    render json: {
      tasks: json_tasks(tasks)
    }
  end

  private

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
