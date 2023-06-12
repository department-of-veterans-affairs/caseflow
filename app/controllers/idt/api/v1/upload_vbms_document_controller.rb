# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  include ApiRequestLoggingConcern

  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  def create
    # Validate copies and create distributions for Package Manager mail service if recipient info present
    build_mail_package

    result = PrepareDocumentUploadToVbms.new(params, current_user, appeal).call
    if result.success?
      success_message = { message: "Document successfully queued for upload." }
      if recipient_info.present?
        success_message[:distribution_ids] = distribution_ids
      end
      render json: success_message
    else
      render json: result.errors[0], status: :bad_request
    end
  end

  private

  def recipient_info
    params[:recipient_info]
  end

  def copies
    # Default value of 1 for copies
    return 1 if params[:copies].blank?

    params[:copies]
  end

  # Payload with distributions value (array of JSON-formatted MailRequest objects) and copies (integer)
  def mail_package
    return nil if recipient_info.blank?

    { distributions: mail_requests, copies: copies }
  end

  def build_mail_package
    return if recipient_info.blank?

    throw_error_if_copies_out_of_range
    # Create and validate MailRequest objects, save to database, and store distribution IDs
    mail_requests.map do |request|
      request.call
      distribution_ids << request.vbms_distribution_id
    end
    params[:mail_package] = mail_package
  end

  def mail_requests
    @mail_requests ||= create_mail_requests_and_track_errors
  end

  def create_mail_requests_and_track_errors
    requests = recipient_info.map.with_index do |recipient, idx|
      MailRequest.new(recipient).tap do |request|
        if request.invalid?
          recipient_errors["distribution #{idx + 1}"] = request.errors.full_messages.join(", ")
        end
      end
    end
    throw_error_if_recipient_info_invalid
    requests
  end

  def throw_error_if_copies_out_of_range
    unless (1..500).cover?(copies)
      fail Caseflow::Error::MissingRecipientInfo, "Copies must be between 1 and 500 (inclusive)".to_json
    end
  end

  def throw_error_if_recipient_info_invalid
    return unless recipient_errors.any?

    fail Caseflow::Error::MissingRecipientInfo, recipient_errors.to_json
  end

  def recipient_errors
    @recipient_errors ||= {}
  end

  def distribution_ids
    @distribution_ids ||= []
  end

  def vbms_upload_params
    params[:mail_package] = mail_package
    {
      params: params,
      user: current_user,
      appeal: appeal
    }
  end

  def appeal_id
    params[:appeal_id]
  end

  def veteran_identifier
    params[:veteran_identifier]
  end

  def bgs
    @bgs ||= BGSService.new
  end

  def appeal
    if appeal_id.blank?
      find_file_number_by_veteran_identifier
      return nil
    end

    @appeal ||= find_veteran_by_appeal_id
  end

  def find_veteran_by_appeal_id
    appeal = LegacyAppeal.find_by_vacols_id(appeal_id) || Appeal.find_by_uuid(appeal_id)
    throw_not_found_error(Caseflow::Error::AppealNotFound, "appeal") if appeal.nil?
    update_veteran_file_number(appeal.veteran_file_number)
    appeal
  end

  def find_file_number_by_veteran_identifier
    file_number = bgs.fetch_veteran_info(veteran_identifier)&.dig(:file_number) ||
                  bgs.fetch_file_number_by_ssn(veteran_identifier)
    throw_not_found_error(Caseflow::Error::VeteranNotFound, "veteran") if file_number.nil?
    update_veteran_file_number(file_number)
  end

  def update_veteran_file_number(file_number)
    params["veteran_file_number"] = file_number
  end

  def throw_not_found_error(error, name)
    uuid = SecureRandom.uuid
    fail error, uuid + " The #{name} was unable to be found."
  end
end
