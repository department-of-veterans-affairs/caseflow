# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DecisionReviewUpdated::DecisionReviewUpdatedParser do
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
    file_path = Rails.root.join("app", "services", "events", "decision_review_updated",
                                "decision_review_updated_example.json")
    JSON.parse(File.read(file_path))
  end

  let(:added_issues_payload) do
    [{
      decision_review_issue_id: 1,
      benefit_type: "compensation",
      closed_at: 1_625_151_600,
      closed_status: "withdrawn",
      contention_reference_id: 7_905_752,
      contested_decision_issue_id: 201,
      contested_issue_description: "Service connection for PTSD",
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: "9411",
      contested_rating_issue_profile_date: 1_625_076_000,
      contested_rating_issue_reference_id: "REF9411",
      type: "RequestIssue",
      original_caseflow_request_issue_id: nil,
      decision: [
        {
          award_event_id: 679,
          category: "decision",
          contention_id: 35,
          decision_finalized_time: nil,
          decision_recorded_time: nil,
          decision_source: "the source",
          decision_text: "",
          description: nil,
          disposition: nil,
          dta_error_explanation: nil,
          id: 1738,
          rating_profile_date: nil
        }
      ],
      decision_date: 19_568,
      ineligible_due_to_id: 301,
      ineligible_reason: nil,
      is_unidentified: false,
      nonrating_issue_bgs_id: "13",
      nonrating_issue_bgs_source: "CORP_AWARD_ATTORNEY_FEE",
      nonrating_issue_category: "Accrued Benefits",
      nonrating_issue_description: "Chapter 35 benefits",
      ramp_claim_id: "RAMP123",
      rating_issue_associated_at: 1_625_076_000,
      unidentified_issue_text: nil,
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      vacols_id: "VAC123",
      vacols_sequence_id: nil
    }]
  end

  subject { described_class.new(headers, payload) }

  describe "attributes" do
    it "returns the correct event_id" do
      expect(subject.event_id).to eq(1)
    end

    it "returns the correct css_id" do
      expect(subject.css_id).to eq("CSEM123")
    end

    it "returns the correct detail_type" do
      expect(subject.detail_type).to eq("HigherLevelReview")
    end

    it "returns the correct station" do
      expect(subject.station_id).to eq("123")
    end

    describe "claim_review" do
      it "returns the correct informal_conference" do
        expect(subject.claim_review_informal_conference).to eq(false)
      end

      it "returns the correct same_office" do
        expect(subject.claim_review_same_office).to eq(true)
      end

      it "returns the correct legacy_opt_in_approved" do
        expect(subject.claim_review_legacy_opt_in_approved).to eq(false)
      end
    end

    describe "end_product_establishments" do
      it "returns the correct development_item_reference_id" do
        expect(subject.end_product_establishments_development_item_reference_id).to eq("DEV123")
      end

      it "returns the correct reference_id" do
        expect(subject.end_product_establishments_reference_id).to eq("REF123")
      end
    end

    # We are testing that each attribute returns the correct value
    describe "updated_issues" do
      it "returns an empty array if no updated issues" do
        expect(subject.updated_issues).to eq([])
      end
    end

    describe "added_issues" do
      it "returns an empty array if no updated issues" do
        expect(subject.added_issues).to eq(added_issues_payload)
      end
    end

    describe "eligible_to_ineligible_issues" do
      it "returns an empty array if no eligible_to_ineligible_issues" do
        expect(subject.eligible_to_ineligible_issues).to eq([])
      end
    end

    describe "ineligible_to_eligible_issues" do
      it "returns an empty array if no ineligible_to_eligible_issues" do
        expect(subject.ineligible_to_eligible_issues).to eq([])
      end
    end

    describe "ineligible_to_ineligible_issues" do
      it "returns an empty array if no ineligible_to_ineligible_issues" do
        expect(subject.ineligible_to_ineligible_issues).to eq([])
      end
    end

    describe "withdrawn_issues" do
      it "returns an empty array if no uwithdrawn_issues" do
        expect(subject.withdrawn_issues).to eq([])
      end
    end

    describe "removed_issues" do
      it "returns an empty array if no removed_issues" do
        expect(subject.removed_issues).to eq([])
      end
    end

    describe "ep_code" do
      it "returns the correct ep_code" do
        expect(subject.ep_code).to eq(payload["ep_code"])
      end
    end

    describe "ep_code_category" do
      it "returns the correct ep_code_category" do
        expect(subject.ep_code_category).to eq(payload["ep_code_category"])
      end
    end

    describe "original_source" do
      it "returns the correct original_source" do
        expect(subject.original_source).to eq(payload["original_source"])
      end
    end

    describe "decision_review_type" do
      it "returns the correct decision_review_type" do
        expect(subject.decision_review_type).to eq(payload["decision_review_type"])
      end
    end

    describe "veteran_first_name" do
      it "returns the correct veteran_first_name" do
        expect(subject.veteran_first_name).to eq(payload["veteran_first_name"])
      end
    end

    describe "veteran_last_name" do
      it "returns the correct veteran_last_name" do
        expect(subject.veteran_last_name).to eq(payload["veteran_last_name"])
      end
    end

    describe "veteran_participant_id" do
      it "returns the correct veteran_participant_id" do
        expect(subject.veteran_participant_id).to eq(payload["veteran_participant_id"])
      end
    end

    describe "file_number" do
      it "returns the correct file_number" do
        expect(subject.file_number).to eq(payload["file_number"])
      end
    end

    describe "claimant_participant_id" do
      it "returns the correct claimant_participant_id" do
        expect(subject.claimant_participant_id).to eq(payload["claimant_participant_id"])
      end
    end

    describe "claim_category" do
      it "returns the correct claim_category" do
        expect(subject.claim_category).to eq(payload["claim_category"])
      end
    end

    describe "claim_received_date" do
      it "returns the correct claim_received_date" do
        expect(subject.claim_received_date).to eq(payload["claim_received_date"])
      end
    end

    describe "claim_lifecycle_status" do
      it "returns the correct claim_lifecycle_status" do
        expect(subject.claim_lifecycle_status).to eq(payload["claim_lifecycle_status"])
      end
    end

    describe "payee_code" do
      it "returns the correct payee_code" do
        expect(subject.payee_code).to eq(payload["payee_code"])
      end
    end

    describe "ols_issue" do
      it "returns the correct ols_issue" do
        expect(subject.ols_issue).to eq(payload["ols_issue"])
      end
    end

    describe "originated_from_vacols_issue" do
      it "returns the correct originated_from_vacols_issue" do
        expect(subject.originated_from_vacols_issue).to eq(payload["originated_from_vacols_issue"])
      end
    end

    describe "limited_poa_code" do
      it "returns the correct limited_poa_code" do
        expect(subject.limited_poa_code).to eq(payload["limited_poa_code"])
      end
    end

    describe "tracked_item_action" do
      it "returns the correct tracked_item_action" do
        expect(subject.tracked_item_action).to eq(payload["tracked_item_action"])
      end
    end

    describe "tracked_item_id" do
      it "returns the correct tracked_item_id" do
        expect(subject.tracked_item_id).to eq(payload["tracked_item_id"])
      end
    end

    describe "informal_conference_requested" do
      it "returns the correct informal_conference_requested" do
        expect(subject.informal_conference_requested).to eq(payload["informal_conference_requested"])
      end
    end

    describe "same_station_review_requested" do
      it "returns the correct same_station_review_requested" do
        expect(subject.same_station_review_requested).to eq(payload["same_station_review_requested"])
      end
    end

    describe "claim_time" do
      it "returns the correct claim_time" do
        expect(subject.claim_time).to eq(payload["claim_time"])
      end
    end

    describe "catror_username" do
      it "returns the correct catror_username" do
        expect(subject.catror_username).to eq(payload["catror_username"])
      end
    end

    describe "catror_application" do
      it "returns the correct catror_application" do
        expect(subject.catror_application).to eq(payload["catror_application"])
      end
    end

    describe "auto_remand" do
      it "returns the correct auto_remand" do
        expect(subject.auto_remand).to eq(payload["auto_remand"])
      end
    end

  end

  context "when attributes use .presence and values are empty strings" do
    let(:empty_payload) do
      payload.merge(
        css_id: "",
        detail_type: "",
        end_product_establishments: {
          development_item_reference_id: "",
          reference_id: ""
        }
      )
    end

    subject { described_class.new(headers, empty_payload) }

    it "returns nil for css_id if the value is an empty string" do
      expect(subject.css_id).to be_nil
    end

    it "returns nil for detail_type if the value is an empty string" do
      expect(subject.detail_type).to be_nil
    end

    it "returns nil for development_item_reference_id if the value is an empty string" do
      expect(subject.end_product_establishments_development_item_reference_id).to be_nil
    end

    it "returns nil for reference_id if the value is an empty string" do
      expect(subject.end_product_establishments_reference_id).to be_nil
    end
  end
end
