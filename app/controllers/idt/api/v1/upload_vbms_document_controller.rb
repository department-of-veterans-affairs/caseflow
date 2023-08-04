# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  include ApiRequestLoggingConcern
  include MailPackageConcern

  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  def create
    # Create distributions for Package Manager mail service if recipient info present
    build_mail_package

    result = PrepareDocumentUploadToVbms.new(params, current_user, appeal, mail_package).call

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

  # Find veteran from appeal id and check with db
  def appeal
    if appeal_id.blank?
      find_file_number_by_veteran_identifier
      return nil
    end

    @appeal ||= find_veteran_by_appeal_id
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
