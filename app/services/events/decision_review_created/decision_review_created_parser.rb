# frozen_string_literal: true

# Parser Class that will be used to extract out datapoints from headers & payload for use with
# DecisionReviewCreated and it's service Classes
class Events::DecisionReviewCreated::DecisionReviewCreatedParser
  include Events::VeteranExtractorInterface

  attr_reader :headers, :payload

  class << self
    # This method reads the drc_example.json file for our load_example method
    def example_response
      File.read(Rails.root.join("app",
                                "services",
                                "events",
                                "decision_review_created",
                                "decision_review_created_example.json"))
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

  # Generic/universal methods
  def convert_milliseconds_to_datetime(milliseconds)
    milliseconds.nil? ? nil : Time.at(milliseconds.to_i / 1000).to_datetime
  end

  # convert logical date int to date
  def logical_date_converter(logical_date_int)
    return nil if logical_date_int.nil? || logical_date_int.to_i.days == 0

    base_date = Date.new(1970, 1, 1)
    converted_date = base_date + logical_date_int.to_i.days
    return converted_date
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

  def event_id
    @payload.dig(:event_id)
  end

  def claim_id
    @payload.dig(:claim_id)
  end

  # Intake attributes
  def intake
    @payload.dig(:intake)
  end

  def intake_started_at
    intake_started_at_milliseconds = @payload.dig(:intake, :started_at)
    convert_milliseconds_to_datetime(intake_started_at_milliseconds)
  end

  def intake_completion_started_at
    intake_completetion_start_at_milliseconds = @payload.dig(:intake, :completion_started_at)
    convert_milliseconds_to_datetime(intake_completetion_start_at_milliseconds)
  end

  def intake_completed_at
    intake_completed_at_milliseconds = @payload.dig(:intake, :completed_at)
    convert_milliseconds_to_datetime(intake_completed_at_milliseconds)
  end

  def intake_completion_status
    @payload.dig(:intake, :completion_status)
  end

  def intake_type
    @payload.dig(:intake, :type)
  end

  def intake_detail_type
    @payload.dig(:intake, :detail_type)
  end

  # Veteran attributes
  def veteran
    @payload.dig(:veteran)
  end

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
    @headers["X-VA-Vet-Middle-Name"].presence
  end

  def person_date_of_birth
    dob = @headers["X-VA-Claimant-DOB"].presence
    convert_milliseconds_to_datetime(dob)
  end

  def person_email_address
    @headers["X-VA-Claimant-Email"].presence
  end

  def person_first_name
    @headers["X-VA-Claimant-First-Name"].presence
  end

  def person_last_name
    @headers["X-VA-Claimant-Last-Name"].presence
  end

  def person_middle_name
    byebug
    @headers["X-VA-Claimant-Middle-Name"].presence
  end

  def person_ssn
    @headers["X-VA-Claimant-SSN"].presence
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
    date_of_death = @payload.dig(:veteran, :date_of_death)
    logical_date_converter(date_of_death)
  end

  # Claimant attributes
  def claimant
    @payload.dig(:claimant)
  end

  def claimant_payee_code
    @payload.dig(:claimant, :payee_code)
  end

  def claimant_type
    @payload.dig(:claimant, :type)
  end

  def claimant_participant_id
    @payload.dig(:claimant, :participant_id)
  end

  def claimant_name_suffix
    @payload.dig(:claimant, :name_suffix)
  end

  # ClaimReview attributes
  def claim_review
    @payload.dig(:claim_review)
  end

  def claim_review_benefit_type
    @payload.dig(:claim_review, :benefit_type)
  end

  def claim_review_filed_by_va_gov
    @payload.dig(:claim_review, :filed_by_va_gov)
  end

  def claim_review_legacy_opt_in_approved
    @payload.dig(:claim_review, :legacy_opt_in_approved)
  end

  def claim_review_receipt_date
    receipt_date_logical_int_date = @payload.dig(:claim_review, :receipt_date)
    logical_date_converter(receipt_date_logical_int_date)
  end

  def claim_review_veteran_is_not_claimant
    @payload.dig(:claim_review, :veteran_is_not_claimant)
  end

  def claim_review_establishment_attempted_at
    establishment_attempted_at_in_milliseconds = @payload.dig(:claim_review, :establishment_attempted_at)
    convert_milliseconds_to_datetime(establishment_attempted_at_in_milliseconds)
  end

  def claim_review_establishment_last_submitted_at
    establishment_last_submitted_at_in_milliseconds = @payload.dig(:claim_review, :establishment_last_submitted_at)
    convert_milliseconds_to_datetime(establishment_last_submitted_at_in_milliseconds)
  end

  def claim_review_establishment_processed_at
    establishment_processed_at_in_milliseconds = @payload.dig(:claim_review, :establishment_processed_at)
    convert_milliseconds_to_datetime(establishment_processed_at_in_milliseconds)
  end

  def claim_review_establishment_submitted_at
    establishment_submitted_at_in_milliseconds = @payload.dig(:claim_review, :establishment_submitted_at)
    convert_milliseconds_to_datetime(establishment_submitted_at_in_milliseconds)
  end

  def claim_review_informal_conference
    @payload.dig(:claim_review, :informal_conference)
  end

  def claim_review_same_office
    @payload.dig(:claim_review, :same_office)
  end

  # EndProductEstablishment attr
  def epe
    @payload.dig(:end_product_establishment)
  end

  def epe_benefit_type_code
    @payload.dig(:end_product_establishment, :benefit_type_code)
  end

  def epe_claim_date
    logical_date_int = @payload.dig(:end_product_establishment, :claim_date)
    logical_date_converter(logical_date_int)
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
    committed_at_milliseconds = @payload.dig(:end_product_establishment, :committed_at)
    convert_milliseconds_to_datetime(committed_at_milliseconds)
  end

  def epe_established_at
    established_at_milliseconds = @payload.dig(:end_product_establishment, :established_at)
    convert_milliseconds_to_datetime(established_at_milliseconds)
  end

  def epe_last_synced_at
    last_synced_at_milliseconds = @payload.dig(:end_product_establishment, :last_synced_at)
    convert_milliseconds_to_datetime(last_synced_at_milliseconds)
  end

  def epe_synced_status
    @payload.dig(:end_product_establishment, :synced_status)
  end

  def epe_development_item_reference_id
    @payload.dig(:end_product_establishment, :development_item_reference_id)
  end

  # RequestIssues attr
  # return the array of RI objects
  def request_issues
    @payload.dig(:request_issues)
  end

  # Individual RequestIssue parsing methods
  # An RI instance will be passed in as you iterate through the array
  def ri_benefit_type(issue)
    issue.dig(:benefit_type)
  end

  def ri_contested_issue_description(issue)
    issue.dig(:contested_issue_description)
  end

  def ri_contention_reference_id(issue)
    issue.dig(:contention_reference_id)
  end

  def ri_contested_rating_decision_reference_id(issue)
    issue.dig(:contested_rating_decision_reference_id)
  end

  def ri_contested_rating_issue_profile_date(issue)
    issue.dig(:contested_rating_issue_profile_date)
  end

  def ri_contested_rating_issue_reference_id(issue)
    issue.dig(:contested_rating_issue_reference_id)
  end

  def ri_contested_decision_issue_id(issue)
    issue.dig(:contested_decision_issue_id)
  end

  def ri_decision_date(issue)
    decision_date_int = issue.dig(:decision_date)
    logical_date_converter(decision_date_int)
  end

  def ri_ineligible_due_to_id(issue)
    issue.dig(:ineligible_due_to_id)
  end

  def ri_ineligible_reason(issue)
    issue.dig(:ineligible_reason)
  end

  def ri_is_unidentified(issue)
    issue.dig(:is_unidentified)
  end

  def ri_unidentified_issue_text(issue)
    issue.dig(:unidentified_issue_text)
  end

  def ri_nonrating_issue_category(issue)
    issue.dig(:nonrating_issue_category)
  end

  def ri_nonrating_issue_description(issue)
    issue.dig(:nonrating_issue_description)
  end

  def ri_untimely_exemption(issue)
    issue.dig(:untimely_exemption)
  end

  def ri_untimely_exemption_notes(issue)
    issue.dig(:untimely_exemption_notes)
  end

  def ri_vacols_id(issue)
    issue.dig(:vacols_id)
  end

  def ri_vacols_sequence_id(issue)
    issue.dig(:vacols_sequence_id)
  end

  def ri_closed_at(issue)
    issue.dig(:closed_at)
  end

  def ri_closed_status(issue)
    issue.dig(:closed_status)
  end

  def ri_contested_rating_issue_diagnostic_code(issue)
    issue.dig(:contested_rating_issue_diagnostic_code)
  end

  def ri_ramp_claim_id(issue)
    issue.dig(:ramp_claim_id)
  end

  def ri_rating_issue_associated_at(issue)
    issue.dig(:rating_issue_associated_at)
  end

  def ri_nonrating_issue_bgs_id(issue)
    issue.dig(:nonrating_issue_bgs_id)
  end

  def ri_nonrating_issue_bgs_source(issue)
    issue.dig(:nonrating_issue_bgs_source)
  end
end
