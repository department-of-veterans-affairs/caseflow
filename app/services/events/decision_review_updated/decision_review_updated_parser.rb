# frozen_string_literal: true

# Parser Class that will be used to extract out datapoints from headers & payload for use with
# DecisionReviewUpdated and it's service Classes
class Events::DecisionReviewUpdated::DecisionReviewUpdatedParser
  include Events::VeteranExtractorInterface
  include ParserHelper

  attr_reader :headers, :payload

  class << self
    # This method reads the drc_example.json file for our load_example method
    def example_response
      File.read(Rails.root.join("app",
                                "services",
                                "events",
                                "decision_review_updated",
                                "decision_review_updated_example.json"))
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
    @veteran = @payload.dig(:veteran)
  end

  def event_id
    @payload[:event_id]
  end

  def css_id
    @payload[:css_id]
  end

  def detail_type
    @payload[:detail_type]
  end

  def station
    @payload[:station]
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

  def end_product_establishments_development_item_reference_id
    @payload.dig(:end_product_establishments, :development_item_reference_id)
  end

  def end_product_establishments_reference_id
    @payload.dig(:end_product_establishments, :reference_id)
  end

  def added_issues
    @payload[:added_issues] || []
  end

  def updated_issues
    @payload[:updated_issues] || []
  end

  def eligible_to_ineligible_issues
    @payload[:eligible_to_ineligible_issues] || []
  end

  def ineligible_to_eligible_issues
    @payload[:ineligible_to_eligible_issues] || []
  end

  def ineligible_to_ineligible_issues
    @payload[:ineligible_to_ineligible_issues] || []
  end

  def withdrawn_issues
    @payload[:withdrawn_issues] || []
  end

  def removed_issues
    @payload[:removed_issues] || []
  end
end