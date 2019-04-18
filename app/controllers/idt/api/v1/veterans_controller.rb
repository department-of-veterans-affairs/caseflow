# frozen_string_literal: true

class Idt::Api::V1::VeteransController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  # :nocov:
  rescue_from StandardError do |error|
    Raven.capture_exception(error)
    if error.class.method_defined?(:serialize_response)
      render(error.serialize_response)
    else
      render json: { message: "Unexpected error: #{error.message}" }, status: :internal_server_error
    end
  end
  # :nocov:

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render(json: { message: "A veteran with that file number could not be found." }, status: :not_found)
  end

  rescue_from Caseflow::Error::InvalidFileNumber do |_e|
    render(json: { message: "Please enter a file number in the 'FILENUMBER' header" }, status: :unprocessable_entity)
  end

  def details
    render json: json_veteran_details
  end

  private

  def bgs
    @bgs ||= BGSService.new
  end

  def veteran
    fail Caseflow::Error::InvalidFileNumber if file_number.blank?

    @veteran ||= begin
      veteran = bgs.fetch_veteran_info(file_number)
      fail ActiveRecord::RecordNotFound unless veteran

      veteran
    end
  end

  def poa
    @poa ||= begin
      poa = bgs.fetch_poa_by_file_number(veteran[:file_number])
      poa.merge(bgs.find_address_by_participant_id(poa[:participant_id]))
    end
  end

  def json_veteran_details
    veteran.merge(poa: poa)
  end
end
