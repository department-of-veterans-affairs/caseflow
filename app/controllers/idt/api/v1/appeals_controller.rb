class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  rescue_from StandardError do |e|
    fail e unless e.class.method_defined?(:serialize_response)
    Raven.capture_exception(e)
    render(e.serialize_response)
  end

  def list
    appeals = file_number ? appeals_by_file_number : appeals_assigned_to_user

    render json: json_appeals(appeals)
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

  def appeals_assigned_to_user
    appeals = LegacyWorkQueue.tasks_with_appeals(user, "attorney")[1].select(&:active?)

    if feature_enabled?(:idt_ama_appeals)
      appeals += Task.where(assigned_to: user).where.not(status: [:completed, :on_hold]).map(&:appeal)
    end
    appeals
  end

  def legacy_appeal_details
    legacy_tasks = QueueRepository.tasks_for_appeal(appeal.vacols_id)
    [legacy_tasks.last ? legacy_tasks.last.assigned_by_name : "", legacy_tasks]
  end

  def ama_appeal_details
    task = Task.where(assigned_to: user, appeal: appeal).where.not(status: [:completed, :on_hold]).last
    documents = Task.where(appeal: appeal).map(&:attorney_case_reviews).flatten
    [task ? task.assigned_by.full_name : "", documents]
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
    appeal_details = ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: ::Idt::V1::AppealDetailsSerializer,
      include_addresses: Constants::BvaDispatchTeams::USERS[Rails.current_env].include?(user.css_id)
    ).as_json

    assigned_by_name, documents = appeal.is_a?(LegacyAppeal) ? legacy_appeal_details : ama_appeal_details

    appeal_details[:data][:attributes][:assigned_by] = assigned_by_name
    appeal_details[:data][:attributes][:documents] = documents.reject { |t| t.document_id.nil? }.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
    appeal_details
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end
end
