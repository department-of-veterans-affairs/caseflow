# frozen_string_literal: true

# Parser Class that will be used to extract out datapoints from headers & payload for use with
# DecisionReviewCompleted and it's service Classes

# This class was created with the assumption that the logic for the Complete event would be
#  very similar to that of the Update event, and it will need to be adjusted in the future.
class Events::DecisionReviewCompleted::DecisionReviewCompletedParser
  include Events::VeteranExtractorInterface
  include ParserHelper

  attr_reader :headers, :payload

  class << self
    # This method reads the drc_example.json file for our load_example method
    def example_response
      File.read(Rails.root.join("app",
                                "services",
                                "events",
                                "decision_review_completed",
                                "decision_review_completed_example.json"))
    end

    # This method creates a new instance of DecisionReviewCreatedParser in order to
    # mimic the parsing of a payload recieved by appeals-consumer
    # arguments being passed in are the sample_header and example_response
    def load_example
      sample_header = {
        "X-VA-Vet-SSN" => "123456789",
        "X-VA-File-Number" => "77799777",
        "X-VA-Vet-First-Name" => "John",
        "X-VA-Vet-Last-Name" => "Smith",
        "X-VA-Vet-Middle-Name" => "Alexander"
      }
      new(sample_header, JSON.parse(example_response))
    end
  end

  def initialize(headers, payload_json)
    @payload = payload_json.to_h.deep_symbolize_keys
    @headers = headers
  end

  def event_id
    @payload[:event_id]
  end

  def css_id
    @payload[:css_id].presence
  end

  def station_id
    @payload[:station].presence
  end

  def claim_review_informal_conference
    @payload.dig(:claim_review, :informal_conference)
  end

  def claim_review_same_office
    @payload.dig(:claim_review, :same_office)
  end

  def claim_review_legacy_opt_in_approved
    @payload.dig(:claim_review, :legacy_opt_in_approved)
  end

  def claim_review_remand_source_id
    @payload.dig(:claim_review, :remand_source_id)
  end

  def claim_review_auto_remand
    @payload.dig(:claim_review, :auto_remand)
  end

  def end_product_establishment_development_item_reference_id
    @payload.dig(:end_product_establishment, :development_item_reference_id).presence
  end

  def end_product_establishment_reference_id
    @payload.dig(:end_product_establishment, :reference_id).presence
  end

  def end_product_establishment_code
    @payload.dig(:end_product_establishment, :code).presence
  end

  def end_product_establishment_synced_status
    @payload.dig(:end_product_establishment, :synced_status).presence
  end

  def end_product_establishment_last_synced_at
    last_synced_at_milliseconds = @payload.dig(:end_product_establishment, :last_synced_at)
    convert_milliseconds_to_datetime(last_synced_at_milliseconds)
  end

  def completed_issues
    @payload[:completed_issues] || []
  end
end
