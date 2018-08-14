class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  def list
    appeals = file_number ? appeals_by_file_number : appeals_assigned_to_user

    render json: json_appeals(appeals)
  end

  def details
    # TODO: add AMA appeals
    # We query the case assignment table here so we can get information for 
    # who wrote the case decision docs/OMO request and what their doc ids are.
    # For AMA appeals, we should get that information from our attorney and judge case review tables.
    tasks = QueueRepository.tasks_for_appeal(params[:appeal_id])
    appeals = QueueRepository.appeals_by_vacols_ids(params[:appeal_id])
    return render json: { message: "Appeal not found" }, status: 404 if appeals.empty?
    render json: json_appeal_details(tasks, appeals[0])
  end

  def appeals_assigned_to_user
    # TODO: add AMA appeals
    LegacyWorkQueue.tasks_with_appeals(user, "attorney")[1].select(&:active?)
  end

  def appeals_by_file_number
    # TODO: add AMA appeals
    LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:active?)
  end

  def json_appeal_details(task, appeal)
    ActiveModelSerializers::SerializableResource.new(
      { tasks: tasks, appeal }
      serializer: ::Idt::V1::AppealDetailsSerializer
    ).as_json
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end

  def json_appeal(tasks, appeal)
  end
end
