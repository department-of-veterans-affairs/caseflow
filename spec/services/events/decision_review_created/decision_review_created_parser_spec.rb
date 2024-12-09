# frozen_string_literal: true

# rubocop:disable Layout/LineLength

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
    it "has Request Issue attributes" do
      total_issues = parser.request_issues
      expect(total_issues.count).to eq(1)
      issue = total_issues.first
      parser_issues = Events::DecisionReviewCreated::DecisionReviewCreatedIssueParser.new(issue)
      expect(parser_issues.ri_benefit_type).to eq response_hash.request_issues.first["benefit_type"]
      expect(parser_issues.ri_benefit_type).to eq response_hash.request_issues.first["benefit_type"]
      expect(parser_issues.ri_contested_issue_description).to eq response_hash.request_issues.first["contested_issue_description"]
      expect(parser_issues.ri_contention_reference_id).to eq response_hash.request_issues.first["contention_reference_id"]
      expect(parser_issues.ri_contested_rating_decision_reference_id).to eq response_hash.request_issues.first["contested_rating_decision_reference_id"]
      expect(parser_issues.ri_contested_rating_issue_profile_date).to eq response_hash.request_issues.first["contested_rating_issue_profile_date"]
      expect(parser_issues.ri_contested_rating_issue_reference_id).to eq response_hash.request_issues.first["contested_rating_issue_reference_id"]
      expect(parser_issues.ri_contested_decision_issue_id).to eq response_hash.request_issues.first["contested_decision_issue_id"]
      expect(parser_issues.ri_decision_date).to eq parser.logical_date_converter(response_hash.request_issues.first["decision_date"])
      expect(parser_issues.ri_ineligible_due_to_id).to eq response_hash.request_issues.first["ineligible_due_to_id"]
      expect(parser_issues.ri_ineligible_reason).to eq response_hash.request_issues.first["ineligible_reason"]
      expect(parser_issues.ri_is_unidentified).to eq response_hash.request_issues.first["is_unidentified"]
      expect(parser_issues.ri_unidentified_issue_text).to eq response_hash.request_issues.first["unidentified_issue_text"]
      expect(parser_issues.ri_nonrating_issue_category).to eq response_hash.request_issues.first["nonrating_issue_category"]
      expect(parser_issues.ri_nonrating_issue_description).to eq response_hash.request_issues.first["nonrating_issue_description"]
      expect(parser_issues.ri_untimely_exemption).to eq response_hash.request_issues.first["untimely_exemption"]
      expect(parser_issues.ri_untimely_exemption_notes).to eq response_hash.request_issues.first["untimely_exemption_notes"]
      expect(parser_issues.ri_vacols_id).to eq response_hash.request_issues.first["vacols_id"]
      expect(parser_issues.ri_vacols_sequence_id).to eq response_hash.request_issues.first["vacols_sequence_id"]
      expect(parser_issues.ri_closed_at).to eq response_hash.request_issues.first["closed_at"]
      expect(parser_issues.ri_closed_status).to eq response_hash.request_issues.first["closed_status"]
      expect(parser_issues.ri_contested_rating_issue_diagnostic_code).to eq response_hash.request_issues.first["contested_rating_issue_diagnostic_code"]
      expect(parser_issues.ri_ramp_claim_id).to eq response_hash.request_issues.first["ramp_claim_id"]
      expect(parser_issues.ri_rating_issue_associated_at).to eq response_hash.request_issues.first["rating_issue_associated_at"]
      expect(parser_issues.ri_nonrating_issue_bgs_id).to eq response_hash.request_issues.first["nonrating_issue_bgs_id"]
      expect(parser_issues.ri_nonrating_issue_bgs_source).to eq response_hash.request_issues.first["nonrating_issue_bgs_source"]
    end
    describe "#process_nonrating" do
      let(:payload_with_valid_issue) do
        {
          request_issues: [
            {
              nonrating_issue_category: "Disposition",
              contested_decision_issue_id: 1
            }
          ]
        }
      end

      let(:payload_with_invalid_issue) do
        {
          request_issues: [
            {
              nonrating_issue_category: "Other",
              contested_decision_issue_id: nil
            }
          ]
        }
      end

      let(:payload_with_unknown_issue) do
        {
          request_issues: [
            {
              nonrating_issue_category: "Disposition",
              contested_decision_issue_id: 2
            },
            {
              nonrating_issue_category: "Disposition",
              contested_decision_issue_id: 5
            },
            {
              nonrating_issue_category: "Disposition",
              contested_decision_issue_id: 3
            }
          ]
        }
      end

      before do
        create(:decision_issue, id: 1)
        create(:request_issue, contested_decision_issue_id: 1, nonrating_issue_category: "Valid Category")
      end

      it "sets the nonrating_issue_category to 'Unknown Issue Category' when there are multiple matching issues" do
        create(:request_issue, contested_decision_issue_id: 1, nonrating_issue_category: "Another Valid Category")
        parser.process_nonrating_issue_category(payload_with_valid_issue)
        expect(payload_with_valid_issue[:request_issues].first[:nonrating_issue_category]).to eq("Unknown Issue Category")
      end

      it "doesn't change anything if nonrating_issue_category is not Disposition" do
        parser.process_nonrating_issue_category(payload_with_invalid_issue)
        expect(payload_with_invalid_issue[:request_issues].first[:nonrating_issue_category]).to eq("Other")
      end

      it "sets the nonrating_issue_category to 'Unknown Issue Category' for all request issues when the contested_decision_issue_id is not found" do
        parser.process_nonrating_issue_category(payload_with_unknown_issue)
        payload_with_unknown_issue[:request_issues].each do |issue|
          expect(issue[:nonrating_issue_category]).to eq("Unknown Issue Category")
        end
      end
    end
  end

  context "when parsing payload with empty string values" do
    let(:empty_string_payload) do
      {
        css_id: "",
        detail_type: "",
        station: "",
        veteran: { participant_id: "" },
        claimant: { payee_code: "", name_suffix: "" },
        claim_review: { benefit_type: "", receipt_date: "", establishment_submitted_at: "" },
        end_product_establishment: { benefit_type_code: "", claim_date: "", code: "" }
      }
    end

    let(:headers) { sample_headers }

    subject { described_class.new(headers, empty_string_payload) }

    it "parses css_id as nil when empty string" do
      expect(subject.css_id).to be_nil
    end

    it "parses detail_type as nil when empty string" do
      expect(subject.detail_type).to be_nil
    end

    it "parses station_id as nil when empty string" do
      expect(subject.station_id).to be_nil
    end

    it "parses veteran participant_id as nil when empty string" do
      expect(subject.veteran_participant_id).to be_nil
    end

    it "parses claimant payee_code as nil when empty string" do
      expect(subject.claimant_payee_code).to be_nil
    end

    it "parses claimant name_suffix as nil when empty string" do
      expect(subject.claimant_name_suffix).to be_nil
    end

    it "parses claim_review benefit_type as nil when empty string" do
      expect(subject.claim_review_benefit_type).to be_nil
    end

    it "parses end_product_establishment benefit_type_code as nil when empty string" do
      expect(subject.epe_benefit_type_code).to be_nil
    end

    it "parses end_product_establishment claim_date as nil when empty string" do
      expect(subject.epe_claim_date).to be_nil
    end

    it "parses end_product_establishment code as nil when empty string" do
      expect(subject.epe_code).to be_nil
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
      "X-VA-File-Number" => "77799777",
      "X-VA-Vet-First-Name" => "John",
      "X-VA-Vet-Last-Name" => "Smith",
      "X-VA-Vet-Middle-Name" => "Alexander"
    }
  end
end

# rubocop:enable Layout/LineLength
