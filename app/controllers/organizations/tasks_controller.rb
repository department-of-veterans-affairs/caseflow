class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    tasks = GenericQueue.new(user: organization).tasks

    render json: {
      tasks: json_tasks(tasks),
      id: organization.id
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      AppealRepository.eager_load_legacy_appeals_for_tasks(tasks),
      user: current_user
    ).as_json
  end
end
