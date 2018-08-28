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
    appeals = QueueRepository.appeals_by_vacols_ids([params[:appeal_id]])
    return render json: { message: "Appeal not found" }, status: 404 if appeals.empty?
    render json: json_appeal_details(tasks, appeals[0])
  end

  def appeals_assigned_to_user
    appeals = LegacyWorkQueue.tasks_with_appeals(user, "attorney")[1].select(&:active?)
    if feature_enabled?(:idt_ama_appeals)
      appeals += Task.where(assigned_to: user).where.not(status: [:completed, :on_hold]).map(&:appeal)
    end
    appeals
  end

  def appeals_by_file_number
    appeals = LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:active?)
    if feature_enabled?(:idt_ama_appeals)
      appeals += Appeal.where(veteran_file_number: file_number)
    end
    appeals
  end

  def json_appeal_details(tasks, appeal)
    appeal_details = ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: ::Idt::V1::AppealDetailsSerializer
    ).as_json

    return appeal_details if tasks.empty?

    appeal_details[:data][:attributes][:assigned_by] = assigned_by_user(tasks.last)
    appeal_details[:data][:attributes][:documents] = json_documents(tasks)

    appeal_details
  end

  def assigned_by_user(task)
    [task.assigned_by_first_name, task.assigned_by_last_name].join(" ")
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end

  def json_documents(tasks)
    tasks_with_documents = tasks.reject { |t| t.document_id.nil? }

    ActiveModelSerializers::SerializableResource.new(
      tasks_with_documents,
      each_serializer: ::Idt::V1::DocumentSerializer
    ).as_json[:data].map { |doc| doc[:attributes] }
  end
end
