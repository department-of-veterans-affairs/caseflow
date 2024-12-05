# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DecisionReviewCompleted::DecisionReviewCompletedParser do
  include ParserHelper
  let(:headers) do
    {
      "X-VA-Vet-SSN" => "123456789",
      "X-VA-File-Number" => "77799777",
      "X-VA-Vet-First-Name" => "John",
      "X-VA-Vet-Last-Name" => "Smith",
      "X-VA-Vet-Middle-Name" => "Alexander"
    }
  end

  let(:payload) do
    file_path = Rails.root.join("app", "services", "events", "decision_review_completed",
                                "decision_review_completed_example.json")
    JSON.parse(File.read(file_path))
  end

  let(:completed_issues) do
    [{
      id: 12,
      benefit_type: "compensation",
      closed_at: 1_702_067_145_000,
      closed_status: "closed",
      contention_reference_id: 790_575_2,
      contested_decision_issue_id: 123_45,
      contested_issue_description: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      decision_date: 18_475,
      decision_review_issue_id: 908,
      is_unidentified: nil,
      nonrating_issue_bgs_id: "13",
      nonrating_issue_bgs_source: "CORP_AWARD_ATTORNEY_FEE",
      nonrating_issue_category: "Accrued Benefits",
      nonrating_issue_description: "The user entered description if the issue is a nonrating issue",
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "unidentified text",
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil,
      veteran_participant_id: "210002659",
      decision_issue: {
        benefit_type: "compensation",
        contention_reference_id: 7_905_752,
        decision_text: "service connected",
        description: nil,
        diagnostic_code: nil,
        disposition: "Granted",
        end_product_last_action_date: 19_594,
        participant_id: "1826209",
        percent_number: "50",
        rating_issue_reference_id: nil,
        rating_profile_date: nil,
        rating_promulgation_date: nil,
        subject_text: "This broadcast may not be reproduced"
      }
    }]
  end

  subject { described_class.new(headers, payload) }
  describe "attributes" do
    it "returns the correct event_id" do
      expect(subject.event_id).to eq(214_706)
    end

    it "returns the correct css_id" do
      expect(subject.css_id).to eq("BVADWISE101")
    end

    it "returns the correct station" do
      expect(subject.station_id).to eq("101")
    end

    it "returns the correct detail_type" do
      expect(subject.detail_type).to eq("HigherLevelReview")
    end

    describe "claim_review" do
      it "returns the correct informal_conference" do
        expect(subject.claim_review_informal_conference).to eq(false)
      end

      it "returns the correct same_office" do
        expect(subject.claim_review_same_office).to eq(false)
      end

      it "returns the correct legacy_opt_in_approved" do
        expect(subject.claim_review_legacy_opt_in_approved).to eq(false)
      end
    end

    describe "end_product_establishment" do
      it "returns the correct development_item_reference_id" do
        expect(subject.end_product_establishment_development_item_reference_id).to eq("1")
      end

      it "returns the correct reference_id" do
        expect(subject.end_product_establishment_reference_id).to eq("1234567")
      end
    end

    # We are testing that each attribute returns the correct value
    describe "completed_issues" do
      it "returns parsed array of completed issues" do
        expect(subject.completed_issues).to eq(completed_issues)
      end
    end

    describe "end_product_establishment_code" do
      it "returns the correct end_product_establishment_code" do
        expect(subject.end_product_establishment_code).to eq(payload["end_product_establishment"]["code"])
      end
    end

    describe "end_product_establishment_synced_status" do
      it "returns the correct end_product_establishment_synced_status" do
        expect(subject.end_product_establishment_synced_status)
          .to eq(payload["end_product_establishment"]["synced_status"])
      end
    end

    describe "end_product_establishment_last_synced_at" do
      it "returns the correct end_product_establishment_last_synced_at" do
        expect(subject.end_product_establishment_last_synced_at)
          .to eq(convert_milliseconds_to_datetime(payload["end_product_establishment"]["last_synced_at"]))
      end
    end
  end

  context "when attributes use .presence and values are empty strings" do
    let(:empty_payload) do
      payload.merge(
        css_id: "",
        end_product_establishment: {
          development_item_reference_id: "",
          reference_id: ""
        }
      )
    end

    subject { described_class.new(headers, empty_payload) }

    it "returns nil for css_id if the value is an empty string" do
      expect(subject.css_id).to be_nil
    end

    it "returns not nil for development_item_reference_id if the value is not an empty string" do
      expect(subject.end_product_establishment_development_item_reference_id).to be_nil
    end

    it "returns not nil for reference_id if the value is not an empty string" do
      expect(subject.end_product_establishment_reference_id).to be_nil
    end
  end
end
