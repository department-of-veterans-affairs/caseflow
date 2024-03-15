# frozen_string_literal: true

class Events::DecisionReviewCreated::DecisionReviewCreatedParser
  include VeteranExtractorInterface

  attr_reader :event

  def initialize(event, headers, payload)
    @event = event
    @payload = payload
    @headers = headers
  end

  private

  # Veteran attributes
  def veteran
    @message_body.dig(:veteran)
  end

  def file_number
    @veteran_file_number ||= @headers["X-VA-File-Number"].presence
  end

  def ssn
    @veteran_ssn ||= @headers["X-VA-Vet-SSN"].presence
  end

  def first_name
    @headers["X-VA-Vet-First-Name"]
  end

  def last_name
    @headers["X-VA-Vet-Last-Name"]
  end

  def middle_name
    @headers["X-VA-Vet-Middle-Name"]
  end

  def participant_id
    @message_body.dig(:veteran, :participant_id)
  end

  def bgs_last_synced_at
    @message_body.dig(:veteran, :bgs_last_synced_at)
  end

  def name_suffix
    @message_body.dig(:veteran, :name_suffix)
  end

  def date_of_death
    @message_body.dig(:veteran, :date_of_death)
  end

  # Claimant attr

  askldljkas

  # Intake attr


end
