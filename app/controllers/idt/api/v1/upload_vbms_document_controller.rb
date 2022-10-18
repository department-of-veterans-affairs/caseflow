# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  def bgs
    @bgs ||= BGSService.new
  end

  def create
    # Find veteran from appeal id and check with db
    if request.parameters["appeal_id"].present?
      appeal = LegacyAppeal.find_by_vacols_id(request.parameters["appeal_id"]) || Appeal.find_by_uuid(request.parameters["appeal_id"])
      if appeal.nil?
        fail Caseflow::Error::AppealNotFound, SecureRandom.uuid + " The appeal was unable to be found."
      else
        request.parameters["veteran_file_number"] = appeal.veteran_file_number
      end

    # check file number with bgs
    elsif request.parameters["veteran_file_number"].present?
      veteran = bgs.fetch_veteran_info(request.parameters["veteran_file_number"])
      if veteran.nil?
        fail Caseflow::Error::VeteranNotFound, SecureRandom.uuid + " The veteran was unable to be found."
      end

    # Find file number from ssn and check with bgs
    elsif request.parameters["veteran_ssn"].present?
      file_number = bgs.fetch_file_number_by_ssn(request.parameters["veteran_ssn"])
      if file_number.nil?
        fail Caseflow::Error::VeteranNotFound, SecureRandom.uuid + " The veteran was unable to be found."
      end

      request.parameters["veteran_file_number"] = file_number
    end
    result = PrepareDocumentUploadToVbms.new(request.parameters, current_user).call

    if result.success?
      render json: { message: "Document successfully queued for upload." }
    else
      render json: result.errors[0], status: :bad_request
    end
  end
end
