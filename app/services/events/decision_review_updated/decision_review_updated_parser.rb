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

  def claim_review_auto_remand
    @payload.dig(:claim_review, :auto_remand)
  end

  def claim_review_remand_source_id
    @payload.dig(:claim_review, :remand_source_id)
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

  def request_issues
    @payload[:request_issues] || []
  end

  def request_issues_id
    request_issues.map { |issue| issue[:id] }
  end

  def request_issues_benefit_type
    request_issues.map { |issue| issue[:benefit_type] }
  end

  def request_issues_closed_at
    request_issues.map { |issue| issue[:closed_at] }
  end

  def request_issues_closed_status
    request_issues.map { |issue| issue[:closed_status] }
  end

  def request_issues_contention_reference_id
    request_issues.map { |issue| issue[:contention_reference_id] }
  end

  def request_issues_contested_issue_description
    request_issues.map { |issue| issue[:contested_issue_description] }
  end

  def request_issues_contested_rating_issue_diagnostic_code
    request_issues.map { |issue| issue[:contested_rating_issue_diagnostic_code] }
  end

  def request_issues_contested_rating_issue_reference_id
    request_issues.map { |issue| issue[:contested_rating_issue_reference_id] }
  end

  def request_issues_contested_rating_issue_profile_date
    request_issues.map { |issue| issue[:contested_rating_issue_profile_date] }
  end

  def request_issues_contested_decision_issue_id
    request_issues.map { |issue| issue[:contested_decision_issue_id] }
  end

  def request_issues_decision_date
    request_issues.map { |issue| issue[:decision_date] }
  end

  def request_issues_ineligible_due_to_id
    request_issues.map { |issue| issue[:ineligible_due_to_id] }
  end

  def request_issues_ineligible_reason
    request_issues.map { |issue| issue[:ineligible_reason] }
  end

  def request_issues_is_unidentified
    request_issues.map { |issue| issue[:is_unidentified] }
  end

  def request_issues_unidentified_issue_text
    request_issues.map { |issue| issue[:unidentified_issue_text] }
  end

  def request_issues_nonrating_issue_category
    request_issues.map { |issue| issue[:nonrating_issue_category] }
  end

  def request_issues_nonrating_issue_description
    request_issues.map { |issue| issue[:nonrating_issue_description] }
  end

  def request_issues_nonrating_issue_bgs_id
    request_issues.map { |issue| issue[:nonrating_issue_bgs_id] }
  end

  def request_issues_nonrating_issue_bgs_source
    request_issues.map { |issue| issue[:nonrating_issue_bgs_source] }
  end

  def request_issues_ramp_claim_id
    request_issues.map { |issue| issue[:ramp_claim_id] }
  end

  def request_issues_rating_issue_associated_at
    request_issues.map { |issue| issue[:rating_issue_associated_at] }
  end

  def request_issues_untimely_exemption
    request_issues.map { |issue| issue[:untimely_exemption] }
  end

  def request_issues_untimely_exemption_notes
    request_issues.map { |issue| issue[:untimely_exemption_notes] }
  end

  def request_issues_vacols_id
    request_issues.map { |issue| issue[:vacols_id] }
  end

  def request_issues_vacols_sequence_id
    request_issues.map { |issue| issue[:vacols_sequence_id] }
  end

  def request_issues_veteran_participant_id
    request_issues.map { |issue| issue[:veteran_participant_id] }
  end
end
