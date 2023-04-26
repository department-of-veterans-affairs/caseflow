# frozen_string_literal: true

class Idt::Api::V1::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  skip_before_action :verify_authenticity_token, only: [:outcode, :validate]

  rescue_from BGS::AccountLocked do |_e|
    account_locked_error_msg = "Your account is locked. " \
                               "Please contact the VA Enterprise Service Desk to resolve this issue."
    render(json: { message: account_locked_error_msg }, status: :forbidden)
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
    result = BvaDispatchTask.outcode(appeal, outcode_params, user)

    return render json: { message: "Success!" } if result.success?

    render json: { message: result.errors[0] }, status: :bad_request
  end

  def validate
    body = params.require(:request_address).permit!.to_h
    address = OpenStruct.new(body)
    response = VADotGovService.validate_address(format_address(address))
    # specific error handling occurs in va_dot_gov_service/response.rb
    if response.error.present?
      log_error(response.error)
      fail response.error
    end
    render json: format_response(response), status: response.code
  end

  private

  def tasks_assigned_to_user
    tasks = if user.attorney_in_vacols? || user.judge_in_vacols?
              LegacyWorkQueue.tasks_for_user(user).select { |task| task.appeal.activated? }
            else
              []
            end
    tasks += Task.active.where(assigned_to: user)
    tasks.reject do |task|
      task.is_a?(JudgeLegacyAssignTask) || task.is_a?(JudgeAssignTask)
    end
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def appeals_by_file_number
    appeals = LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:activated?)
    appeals += Appeal.active.where(veteran_file_number: file_number)
    appeals
  end

  def outcode_params
    params.permit(:citation_number, :decision_date, :redacted_document_location, :file)
  end

  def json_appeal_details
    ::Idt::V1::AppealDetailsSerializer.new(
      appeal,
      params: {
        include_addresses: include_addresses_in_response?,
        base_url: request.base_url
      }
    )
  end

  def include_addresses_in_response?
    BvaDispatch.singleton.user_has_access?(user) || user.intake_user?
  end

  def json_appeals_with_tasks(tasks)
    tasks.map do |task|
      ::Idt::V1::AppealSerializer.new(
        task.appeal,
        params: { task: task }
      ).serializable_hash[:data]
    end
  end

  def json_appeals(appeals)
    ::Idt::V1::AppealSerializer.new(appeals, is_collection: true)
  end

  def format_address(address)
    Address.new(
      address_line_1: address.address_line_1,
      address_line_2: address.address_line_2,
      address_line_3: address.address_line_3,
      city: address.city,
      state: address.dig(:state_province, :code),
      zip: address.zip_code_5,
      zip4: address.zip_code_4,
      country: address.dig(:request_country, :country_code),
      international_postal_code: address.international_postal_code,
      state_name: address.dig(:state_province, :name),
      country_name: address.dig(:request_country, :country_name),
      address_pou: address.address_pou
    )
  end

  def format_response(response)
    JSON.parse(response.response.raw_body).deep_transform_keys! do |key|
      key.underscore.gsub(/e(\d)/, 'e_\1')
    end
  end
end
