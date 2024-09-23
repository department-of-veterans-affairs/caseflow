# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DecisionReviewUpdated::DecisionReviewUpdatedParser do
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
    file_path = Rails.root.join("app", "services", "events", "decision_review_updated",
                                "decision_review_updated_example.json")
    JSON.parse(File.read(file_path))
  end

  let(:added_issues_payload) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 772_37,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:eligible_to_ineligible_issues_payload) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 123,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:updated_issues) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 908,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:removed_issues) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 8755,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:withdrawn_issues) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 9876,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:ineligible_to_ineligible_issues_payload) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 234,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
    }]
  end

  let(:ineligible_to_eligible_issues_payload) do
    [{
      benefit_type: "compensation",
      closed_at: nil,
      closed_status: nil,
      contention_reference_id: 123_456,
      contested_decision_issue_id: nil,
      contested_issue_description: nil,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      edited_description: "DIC: Service connection denied (UPDATED)",
      decision_date: nil,
      decision_review_issue_id: 876,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: true,
      nonrating_issue_bgs_id: nil,
      nonrating_issue_bgs_source: nil,
      nonrating_issue_category: nil,
      nonrating_issue_description: nil,
      original_caseflow_request_issue_id: 123_45,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      type: "RequestIssue",
      unidentified_issue_text: "An unidentified issue added during the edit",
      untimely_exemption: false,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil
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

    it "returns the correct claim_id" do
      expect(subject.claim_id).to eq(123_456_7)
    end

    it "returns the correct detail_type" do
      expect(subject.detail_type).to eq("HigherLevelReview")
    end

    it "returns the correct station" do
      expect(subject.station_id).to eq("101")
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
        expect(subject.end_product_establishments_development_item_reference_id).to eq("1")
      end

      it "returns the correct reference_id" do
        expect(subject.end_product_establishments_reference_id).to eq("1234567")
      end
    end

    # We are testing that each attribute returns the correct value
    describe "updated_issues" do
      it "returns an empty array if no updated issues" do
        expect(subject.updated_issues).to eq(updated_issues)
      end
    end

    describe "added_issues" do
      it "returns an empty array if no updated issues" do
        expect(subject.added_issues).to eq(added_issues_payload)
      end
    end

    describe "eligible_to_ineligible_issues" do
      it "returns an empty array if no eligible_to_ineligible_issues" do
        expect(subject.eligible_to_ineligible_issues).to eq(eligible_to_ineligible_issues_payload)
      end
    end

    describe "ineligible_to_eligible_issues" do
      it "returns an empty array if no ineligible_to_eligible_issues" do
        expect(subject.ineligible_to_eligible_issues).to eq(ineligible_to_eligible_issues_payload)
      end
    end

    describe "ineligible_to_ineligible_issues" do
      it "returns an empty array if no ineligible_to_ineligible_issues" do
        expect(subject.ineligible_to_ineligible_issues).to eq(ineligible_to_ineligible_issues_payload)
      end
    end

    describe "withdrawn_issues" do
      it "returns an empty array if no uwithdrawn_issues" do
        expect(subject.withdrawn_issues).to eq(withdrawn_issues)
      end
    end

    describe "removed_issues" do
      it "returns an empty array if no removed_issues" do
        expect(subject.removed_issues).to eq(removed_issues)
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

    it "returns nil for detail_type if the value is an empty string" do
      expect(subject.detail_type).to be_nil
    end

    it "returns not nil for development_item_reference_id if the value is not an empty string" do
      expect(subject.end_product_establishments_development_item_reference_id).to be_nil
    end

    it "returns not nil for reference_id if the value is not an empty string" do
      expect(subject.end_product_establishments_reference_id).to be_nil
    end
  end
end
