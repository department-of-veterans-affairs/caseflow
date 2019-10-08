# frozen_string_literal: true

class Idt::Api::V1::VeteransController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

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
      veteran = bgs.fetch_veteran_info(file_number.to_s)
      fail ActiveRecord::RecordNotFound unless veteran

      veteran
    end
  end

  def poa
    @poa ||= fetch_poa_with_address
  end

  def fetch_poa_with_address
    poa = bgs.fetch_poa_by_file_number(veteran[:file_number])

    return {} unless poa

    poa_address = bgs.find_address_by_participant_id(poa[:participant_id])

    return poa unless poa_address

    poa.merge(poa_address)
  end

  def json_veteran_details
    ::Idt::V1::VeteranDetailsSerializer.new(
      veteran,
      params: {
        poa: poa
      }
    ).serializable_hash[:data][:attributes]
  end
end
