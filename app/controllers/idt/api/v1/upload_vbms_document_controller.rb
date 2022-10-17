# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { message: "Unexpected error: #{e.message}" }, status: :internal_server_error
    end
  end

  def log_error(error)
    Raven.capture_exception(error)
    Rails.logger.error(error)
  end

  def bgs
    @bgs ||= BGSService.new
  end

  def create
    # Find veteran from veteran file nummber of ssn
    if request.parameters["veteran_file_number"].present?
      veteran = bgs.fetch_veteran_info(request.parameters["veteran_file_number"])
      if veteran.nil?
        begin
          fail NoAppealError, request.parameters["veteran_file_number"]
        rescue StandardError => error
          log_error(error)
          # render json: { status: 400, error_id: SecureRandom.uuid, error_message: "The veteran was unable to be found." }, status: :not_found
        end
      end
    elsif request.parameters["veteran_ssn"].present?
      file_number = bgs.fetch_file_number_by_ssn(request.parameters["veteran_ssn"])
      if file_number.nil?
        begin
          fail NoAppealError, request.parameters["veteran_ssn"]
        rescue StandardError => error
          log_error(error)
          # render json: { status: 400, error_id: SecureRandom.uuid, error_message: "The veteran was unable to be found." }, status: :not_found
        end
      end
      request.parameters["veteran_file_number"] = file_number

    # Find veteran from appeal id
    elsif request.parameters["appeal_id"].present?
      appeal = LegacyAppeal.find_by_vacols_id(request.parameters["appeal_id"]) || Appeal.find_by_uuid(request.parameters["appeal_id"])
      if appeal.nil?
        begin
          fail NoAppealError, request.parameters["appeal_id"]
        rescue StandardError => error
          log_error(error)
          # render json: { status: 400, error_id: SecureRandom.uuid, error_message: "The appeal was unable to be found." }, status: :not_found
        end
      else
        request.parameters["veteran_file_number"] = appeal.veteran_file_number
      end
    end
    result = PrepareDocumentUploadToVbms.new(request.parameters, current_user).call

    if result.success?
      render json: { message: "Document successfully queued for upload." }
    else
      render json: result.errors[0], status: :bad_request
    end
  end
end
