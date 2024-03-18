# frozen_string_literal: true

class Events::DecisionReviewCreated::DecisionReviewCreatedParser
  include Events::VeteranExtractorInterface

  attr_reader :headers, :payload

  def initialize(headers, payload)
    @payload = payload
    @headers = headers
    @veteran = @payload.dig(:veteran)
  end


  # Generic/universal methods
  def convert_milliseconds_to_datetime(milliseconds)
    Time.at(milliseconds / 1000).to_datetime
  end

  def css_id
    @payload.dig(:css_id)
  end

  def detail_type
    @payload.dig(:detail_type)
  end

  def station_id
    @payload.dig(:station)
  end

  # Veteran attributes
  def veteran_file_number
    @veteran_file_number ||= @headers["X-VA-File-Number"].presence
  end

  def veteran_ssn
    @veteran_ssn ||= @headers["X-VA-Vet-SSN"].presence
  end

  def veteran_first_name
    @headers["X-VA-Vet-First-Name"]
  end

  def veteran_last_name
    @headers["X-VA-Vet-Last-Name"]
  end

  def veteran_middle_name
    @headers["X-VA-Vet-Middle-Name"]
  end

  def veteran_participant_id
    @payload.dig(:veteran, :participant_id)
  end

  def veteran_bgs_last_synced_at
    bgs_last_synced_at_milliseconds = @payload.dig(:veteran, :bgs_last_synced_at)
    convert_milliseconds_to_datetime(bgs_last_synced_at_milliseconds)
  end

  def veteran_name_suffix
    @payload.dig(:veteran, :name_suffix)
  end

  def veteran_date_of_death
    @payload.dig(:veteran, :date_of_death)
  end

  # Claimant attr

  # Intake attr

  # EndProductEstablishment attr
  def epe_benefit_type_code
    @payload.dig(:end_product_establishment, :benefit_type_code)
  end

  def epe_claim_date
    @payload.dig(:end_product_establishment, :claim_date)
  end

  def epe_code
    @payload.dig(:end_product_establishment, :code)
  end

  def epe_modifier
    @payload.dig(:end_product_establishment, :modifier)
  end

  def epe_payee_code
    @payload.dig(:end_product_establishment, :payee_code)
  end

  def epe_reference_id
    @payload.dig(:end_product_establishment, :reference_id)
  end

  def epe_limited_poa_access
    @payload.dig(:end_product_establishment, :limited_poa_access)
  end

  def epe_limited_poa_code
    @payload.dig(:end_product_establishment, :limited_poa_code)
  end

  def epe_committed_at
    @payload.dig(:end_product_establishment, :committed_at)
  end

  def epe_established_at
    @payload.dig(:end_product_establishment, :established_at)
  end

  def epe_last_synced_at
    @payload.dig(:end_product_establishment, :last_synced_at)
  end

  def epe_synced_status
    @payload.dig(:end_product_establishment, :synced_status)
  end

  def epe_development_item_reference_id
    @payload.dig(:end_product_establishment, :development_item_reference_id)
  end
end
