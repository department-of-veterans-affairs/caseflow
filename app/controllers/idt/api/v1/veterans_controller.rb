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
    bgs_poa = BgsPowerOfAttorney.new(file_number: veteran[:file_number])

    return {} unless bgs_poa.found?

    poa_address = bgs_poa.representative_address

    poa = {
      representative_name: bgs_poa.representative_name,
      representative_type: bgs_poa.representative_type,
      participant_id: bgs_poa.poa_participant_id
    }

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
