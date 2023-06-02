# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  include ApiRequestLoggingConcern

  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  def bgs
    @bgs ||= BGSService.new
  end

  def create
    success_json = {
      message: "Document successfully queued for upload."
    }
    begin
      if params["recipient_info"].present?
        success_json[:distribution_ids] = params["recipient_info"].map do |recipient|
          mail_req = MailRequest.new(recipient)
          if mail_req.invalid?
           success_json[:error_messages] = mail_req.errors.messages
          #  byebug
          end
          mail_req.call
          mail_req.vbms_distribution_id
        end
      end
    rescue Caseflow::Error::MissingRecipientInfo => error
      success_json[:errors] = "Incomplete mailing informaiton provided. No mail request was created."
      raise error
    ensure
      appeal = nil
      # Find veteran from appeal id and check with db
      if params["appeal_id"].present?
        appeal = LegacyAppeal.find_by_vacols_id(params["appeal_id"]) || Appeal.find_by_uuid(params["appeal_id"])
        if appeal.nil?
          fail Caseflow::Error::AppealNotFound, "IDT Standard Error ID: " + SecureRandom.uuid + " The appeal was unable to be found."
        else
          params["veteran_file_number"] = appeal.veteran_file_number
        end

      else
        file_number = bgs.fetch_veteran_info(params["veteran_identifier"])&.dig(:file_number) || bgs.fetch_file_number_by_ssn(params["veteran_identifier"])
        if file_number.nil?
          fail Caseflow::Error::VeteranNotFound, "IDT Standard Error ID: " + SecureRandom.uuid + " The veteran was unable to be found."
        end

        params["veteran_file_number"] = file_number
      end
      result = PrepareDocumentUploadToVbms.new(params, current_user, appeal).call
      if result.success?
        render json: success_json
      else
        render json: result.errors[0], status: :bad_request
      end
    end
  end
end
