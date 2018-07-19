class OrganizationalTasksController < OrganizationController
  def index
    tasks = organization.tasks
    render json: { tasks: json_tasks(tasks) }
  end

  def organization_id
    params[:organization_id]
  end

  private

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
