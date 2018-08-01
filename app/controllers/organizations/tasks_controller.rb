class Organizations::TasksController < OrganizationsController
  def index
    tasks = organization.tasks
    appeals = tasks.map(&:appeal).uniq

    render json: {
      tasks: json_tasks(tasks),
      appeals: json_appeals(appeals)
    }
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

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
