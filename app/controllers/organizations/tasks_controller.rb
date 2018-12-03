class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    relevant_tasks = GenericQueue.new(user: organization).relevant_tasks

    render json: {
      tasks: json_tasks(relevant_tasks),
      id: organization.id
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer,
      user: current_user
    ).as_json
  end
end
