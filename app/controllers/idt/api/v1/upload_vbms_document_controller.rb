# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  include ApiRequestLoggingConcern

  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  def create
    # Create distributions for Package Manager mail service if recipient info present
    create_mail_distributions

    appeal = nil
    # Find veteran from appeal id and check with db
    if appeal_id.present?
      appeal = find_veteran_by_appeal_id
    else
      find_file_number_by_veteran_identifier
    end
    result = PrepareDocumentUploadToVbms.new(params, current_user, appeal, mail_requests, copies).call

    if result.success?
      render json: { message: "Document successfully queued for upload." }
    else
      render json: result.errors[0], status: :bad_request
    end
  end

  private

  def recipient_info
    params[:recipient_info]
  end

  def copies
    return 1 if params[:copies].blank?

    params[:copies]
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

  def mail_requests
    return nil if recipient_info.blank?

    # @mail_requests ||= Logic from Jonathan's branch goes here
  end

  def create_mail_distributions
    return if recipient_info.blank?

    throw_error_if_copies_out_of_range
    # Logic from Jonathan's branch goes here
  end

  def throw_error_if_copies_out_of_range
    unless (1..500).cover?(copies)
      fail StandardError, "Copies must be between 1 and 500 (inclusive)"
    end
  end

  def find_veteran_by_appeal_id
    appeal = LegacyAppeal.find_by_vacols_id(appeal_id) || Appeal.find_by_uuid(appeal_id)
    throw_not_found_error("appeal") if appeal.nil?
    update_veteran_file_number(appeal.veteran_file_number)
    appeal
  end

  def find_file_number_by_veteran_identifier
    file_number = bgs.fetch_veteran_info(veteran_identifier)&.dig(:file_number) ||
                  bgs.fetch_file_number_by_ssn(veteran_identifier)
    throw_not_found_error("veteran") if file_number.nil?
    update_veteran_file_number(file_number)
  end

  def update_veteran_file_number(file_number)
    params["veteran_file_number"] = file_number
  end

  def throw_not_found_error(name)
    uuid = SecureRandom.uuid
    fail Caseflow::Error::AppealNotFound, "IDT Standard Error ID: " + uuid + " The #{name} was unable to be found."
  end
end
