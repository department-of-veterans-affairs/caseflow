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
    # creating a JSON object that will be used to communicate with the IDT user as to the status of the upload. If it was
    #   successful and if the proper params were supplied, it will also hold the IDs for the created distributions.
    #   allowing the client to be able to search for the status.
    # However, if there are any errors in regards to creation of the MailRequest, the errors will be returned
    #   to the Client and the originally intended upload will still follow through.
    success_json = {
      message: "Document successfully queued for upload."
    }
    begin
      # optional check if the parameters to create a mailrequest are present.
      if params["recipient_info"].present?
        # creating the key for distribution_ids to provide to IDT client within the success_json hash.
        success_json[:distribution_ids] = params["recipient_info"].map do |recipient|
          mail_req = MailRequest.new(recipient)
          # Given that the mail request is invalid, errors will be taken track of and presented to the
          #   user within the success_JSON object.
          if mail_req.invalid?
            success_json[:error_messages] = mail_req.errors.messages
          end
          mail_req.call
          mail_req.vbms_distribution_id
        end
      end
    rescue Caseflow::Error::MissingRecipientInfo => error
      # Raises Caseflow::Error::MissingRecipientInfo if provided params within the recipient_info
      #   array do not create a valid MailRequest.
      success_json[:error] = "Incomplete mailing information provided. No mail request was created."
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
