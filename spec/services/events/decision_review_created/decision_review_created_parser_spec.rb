# frozen_string_literal: true

require "ostruct"

describe Events::DecisionReviewCreated::DecisionReviewCreatedParser do
  context "Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example" do
    let!(:json_payload) { read_json_payload }
    let!(:response_hash) { OpenStruct.new(json_payload) }
    let!(:headers) { sample_headers }
    # mimic when we recieve an example_response
    parser = described_class.load_example
    it "has css_id, detail_type and station_id" do
      expect(parser.css_id).to eq(response_hash.css_id)
      expect(parser.detail_type).to eq(response_hash.detail_type)
      expect(parser.station_id).to eq(response_hash.station)
    end
    it "has Intake attributes" do
      expect(parser.intake_started_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.intake["started_at"]
      )
      expect(parser.intake_completion_started_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.intake["completion_started_at"]
      )
      expect(parser.intake_completed_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.intake["completed_at"]
      )
      expect(parser.intake_completion_status).to eq response_hash.intake["completion_status"]
      expect(parser.intake_type).to eq response_hash.intake["type"]
      expect(parser.intake_detail_type).to eq response_hash.intake["detail_type"]
    end
    it "has Veteran attributes" do
      expect(parser.veteran_file_number).to eq(headers["X-VA-File-Number"])
      expect(parser.veteran_ssn).to eq(headers["X-VA-Vet-SSN"])
      expect(parser.veteran_first_name).to eq(headers["X-VA-Vet-First-Name"])
      expect(parser.veteran_last_name).to eq(headers["X-VA-Vet-Last-Name"])
      expect(parser.veteran_middle_name).to eq(headers["X-VA-Vet-Middle-Name"])
      expect(parser.veteran_participant_id).to eq(response_hash.veteran["participant_id"])
      expect(parser.veteran_bgs_last_synced_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.veteran["bgs_last_synced_at"]
      )
      expect(parser.veteran_name_suffix).to eq(response_hash.veteran["name_suffix"])
      expect(parser.veteran_date_of_death).to eq(response_hash.veteran["date_of_death"])
    end
    it "has Claimant attributes" do
      expect(parser.claimant_payee_code).to eq response_hash.claimant["payee_code"]
      expect(parser.claimant_type).to eq response_hash.claimant["type"]
      expect(parser.claimant_participant_id).to eq response_hash.claimant["participant_id"]
      expect(parser.claimant_name_suffix).to eq response_hash.claimant["name_suffix"]
    end
    it "has Claim Review attributes" do
      expect(parser.claim_review_benefit_type).to eq response_hash.claim_review["benefit_type"]
      expect(parser.claim_review_filed_by_va_gov).to eq response_hash.claim_review["filed_by_va_gov"]
      expect(parser.claim_review_legacy_opt_in_approved).to eq response_hash.claim_review["legacy_opt_in_approved"]
      expect(parser.claim_review_receipt_date).to eq parser.logical_date_converter(
        response_hash.claim_review["receipt_date"]
      )
      expect(parser.claim_review_veteran_is_not_claimant).to eq response_hash.claim_review["veteran_is_not_claimant"]
      expect(parser.claim_review_establishment_attempted_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.claim_review["establishment_attempted_at"]
      )
      expect(parser.claim_review_establishment_last_submitted_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.claim_review["establishment_last_submitted_at"]
      )
      expect(parser.claim_review_establishment_processed_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.claim_review["establishment_processed_at"]
      )
      expect(parser.claim_review_establishment_submitted_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.claim_review["establishment_submitted_at"]
      )
      expect(parser.claim_review_informal_conference).to eq response_hash.claim_review["informal_conference"]
      expect(parser.claim_review_same_office).to eq response_hash.claim_review["same_office"]
    end
    it "has End Product Establishment attributes" do
      expect(parser.epe_benefit_type_code).to eq response_hash.end_product_establishment["benefit_type_code"]
      expect(parser.epe_claim_date).to eq parser.logical_date_converter(
        response_hash.end_product_establishment["claim_date"]
      )
      expect(parser.epe_code).to eq response_hash.end_product_establishment["code"]
      expect(parser.epe_modifier).to eq response_hash.end_product_establishment["modifier"]
      expect(parser.epe_payee_code).to eq response_hash.end_product_establishment["payee_code"]
      expect(parser.epe_reference_id).to eq response_hash.end_product_establishment["reference_id"]
      expect(parser.epe_limited_poa_access).to eq response_hash.end_product_establishment["limited_poa_access"]
      expect(parser.epe_limited_poa_code).to eq response_hash.end_product_establishment["limited_poa_code"]
      expect(parser.epe_committed_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.end_product_establishment["committed_at"]
      )
      expect(parser.epe_established_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.end_product_establishment["established_at"]
      )
      expect(parser.epe_last_synced_at).to eq parser.convert_milliseconds_to_datetime(
        response_hash.end_product_establishment["last_synced_at"]
      )
      expect(parser.epe_synced_status).to eq response_hash.end_product_establishment["synced_status"]
      expect(parser.epe_development_item_reference_id).to eq(
        response_hash.end_product_establishment["development_item_reference_id"]
      )
    end
  end
  def read_json_payload
    JSON.parse(File.read(Rails.root.join("app",
                                         "services",
                                         "events",
                                         "decision_review_created",
                                         "decision_review_created_example.json")))
  end

  def sample_headers
    {
      "X-VA-Vet-SSN" => "123456789",
      "X-VA-File-Number" => "123456789",
      "X-VA-Vet-First-Name" => "John",
      "X-VA-Vet-Last-Name" => "Smith",
      "X-VA-Vet-Middle-Name" => "Alexander"
    }
  end
end
