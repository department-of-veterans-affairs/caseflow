# frozen_string_literal: true

class Idt::Api::V1::VeteransController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { message: "Unexpected error: #{e.message}" }, status: :internal_server_error
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render(json: { message: "A veteran with that SSN was not found in our systems." }, status: :not_found)
  end

  rescue_from Caseflow::Error::InvalidSSN do |_e|
    render(json: { message: "Please enter a valid 9 digit SSN in the 'SSN' header" }, status: :unprocessable_entity)
  end

  def details
    render json: { veteran: veteran, representative: poa }
  end

  private

  def bgs
    @bgs || BGSService.new
  end

  def veteran
    @veteran ||= begin
      fail Caseflow::Error::InvalidSSN if ssn.blank? || ssn.length != 9 || ssn.scan(/\D/).any?

      veteran = bgs.fetch_veteran_by_ssn(ssn)
      fail ActiveRecord::RecordNotFound unless veteran

      veteran
    end
  end

  def poa
    @poa ||= bgs.fetch_poa_by_file_number(veteran[:file_number])
  end

  def include_addresses_in_response?
    BvaDispatch.singleton.user_has_access?(user) || user.intake_user?
  end
end
