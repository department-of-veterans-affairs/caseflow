# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    tasks = GenericQueue.new(user: organization).tasks

    # Temporarily limit hearings-management tasks to AOD tasks, because currently no tasks are loading
    tasks = tasks.select{|t| t.appeal.is_a?(LegacyAppeal) ? t.appeal.aod : true} if organization.id == "20"

    render json: {
      organization_name: organization.name,
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Representative)
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: serializer
    ).call
  end

  def serializer
    organization.is_a?(::Representative) ? WorkQueue::OrganizationTaskSerializer : WorkQueue::TaskSerializer
  end
end
