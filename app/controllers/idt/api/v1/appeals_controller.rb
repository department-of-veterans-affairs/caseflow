class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  skip_before_action :verify_authenticity_token, only: [:outcode]

  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { message: "Unexpected error: #{e.message}" }, status: 500
    end
  end

  rescue_from ActionController::ParameterMissing do |e|
    render(json: { message: e.message }, status: 400)
  end

  rescue_from Caseflow::Error::DocumentUploadFailedInVBMS do |e|
    render(e.serialize_response)
  end

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render(json: { message: "Record not found" }, status: 404)
  end

  def list
    if file_number.present?
      render json: json_appeals(appeals_by_file_number)
    else
      render json: { data: json_appeals_with_tasks(tasks_assigned_to_user) }
    end
  end

  def details
    render json: json_appeal_details
  end

  def outcode
    BvaDispatchTask.outcode(appeal, outcode_params, user)
    render json: { message: "Success!" }
  end

  private

  def tasks_assigned_to_user
    tasks = if user.attorney_in_vacols? || user.judge_in_vacols?
              LegacyWorkQueue.tasks_for_user(user).select { |task| task.appeal.activated? }
            else
              []
            end

    if feature_enabled?(:idt_ama_appeals)
      tasks += Task.where(assigned_to: user).where.not(status: [:completed, :on_hold])
    end
    tasks.reject { |task| (task.is_a?(JudgeLegacyTask) && task.action == "assign") || task.is_a?(JudgeAssignTask) }
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def appeals_by_file_number
    appeals = LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:activated?)
    if feature_enabled?(:idt_ama_appeals)
      appeals += Appeal.where(veteran_file_number: file_number)
    end
    appeals
  end

  def outcode_params
    keys = %w[citation_number decision_date redacted_document_location]
    if feature_enabled?(:decision_document_upload)
      keys << "file"
    end
    params.require(keys)

    # Have to do this because params.require() returns an array of the parameter values.
    keys.map { |k| [k, params[k]] }.to_h
  end

  def json_appeal_details
    ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: ::Idt::V1::AppealDetailsSerializer,
      include_addresses: BvaDispatch.singleton.user_has_access?(user),
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
