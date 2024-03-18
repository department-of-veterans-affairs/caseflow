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


end
