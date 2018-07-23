class Organizations::TasksController < OrganizationsController
  def index
    tasks = organization.tasks
    render json: { tasks: json_tasks(tasks) }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
