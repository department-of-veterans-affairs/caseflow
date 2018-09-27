class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { message: "Unexpected error" }, status: 500
    end
  end

  def list
    if file_number.present?
      render json: json_appeals(appeals_by_file_number)
    else
      render json: { data: json_appeals_with_tasks(tasks_assigned_to_user) }
    end
  end

  def details
    return render json: { message: "Appeal not found" }, status: 404 unless appeal
    render json: json_appeal_details
  end

  def outcode
    BvaDispatchTask.outcode(appeal, user)
    render json: json_appeal_details
  end

  private

  def tasks_assigned_to_user
    tasks = LegacyWorkQueue.tasks_with_appeals(user, role)[0].select { |task| task.appeal.active? }

    if feature_enabled?(:idt_ama_appeals)
      tasks += Task.where(assigned_to: user).where.not(status: [:completed, :on_hold])
        .reject { |task| task.action == "assign" }
    end
    tasks
  end

  def role
    user.vacols_roles.first || "attorney"
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def appeals_by_file_number
    appeals = LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:active?)
    if feature_enabled?(:idt_ama_appeals)
      appeals += Appeal.where(veteran_file_number: file_number)
    end
    appeals
  end

  def json_appeal_details
    ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: ::Idt::V1::AppealDetailsSerializer,
      include_addresses: Constants::BvaDispatchTeams::USERS[Rails.current_env].include?(user.css_id),
      base_url: request.base_url
    ).as_json
  end

  def json_appeals_with_tasks(tasks)
    tasks.map do |task|
      ActiveModelSerializers::SerializableResource.new(
        task.appeal,
        serializer: ::Idt::V1::AppealSerializer,
        task: task
      ).as_json[:data]
    end
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end
end
