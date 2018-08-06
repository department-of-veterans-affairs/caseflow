class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  def index
    appeals = file_number ? appeals_by_file_number : appeals_assigned_to_user

    render json: json_appeals(appeals)
  end

  def details
    # TODO: add AMA appeals
    tasks, appeals = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(params[:id], "attorney")
    render json: json_appeal_details(tasks[0], appeals[0])
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
    json_details = json_appeal(appeal)
    json_details[:data][:attributes][:assigned_by] = task.added_by.try(:name)
    json_details
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end

  def json_appeal(appeal)
    ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: ::Idt::V1::AppealDetailsSerializer
    ).as_json
  end
end
