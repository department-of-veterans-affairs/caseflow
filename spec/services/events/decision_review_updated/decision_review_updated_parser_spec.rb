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
      expect(subject.station).to eq("123")
    end

    describe "claim_review" do
      it "returns the correct auto_remand" do
        expect(subject.claim_review_auto_remand).to eq(true)
      end

      it "returns the correct remand_source_id" do
        expect(subject.claim_review_remand_source_id).to eq(1001)
      end

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

    describe "request_issues" do
      it "returns the correct ids" do
        expect(subject.request_issues_id).to eq([1])
      end

      it "returns the correct benefit types" do
        expect(subject.request_issues_benefit_type).to eq(["compensation"])
      end

      it "returns the correct closed at times" do
        expect(subject.request_issues_closed_at).to eq([162_515_160_0])
      end

      it "returns the correct closed statuses" do
        expect(subject.request_issues_closed_status).to eq(["withdrawn"])
      end

      it "returns the correct contention reference ids" do
        expect(subject.request_issues_contention_reference_id).to eq([101])
      end

      it "returns the correct contested issue descriptions" do
        expect(subject.request_issues_contested_issue_description).to eq(["Service connection for PTSD"])
      end

      it "returns the correct contested rating issue diagnostic codes" do
        expect(subject.request_issues_contested_rating_issue_diagnostic_code).to eq(["9411"])
      end

      it "returns the correct contested rating issue reference ids" do
        expect(subject.request_issues_contested_rating_issue_reference_id).to eq(["REF9411"])
      end

      it "returns the correct contested rating issue profile dates" do
        expect(subject.request_issues_contested_rating_issue_profile_date).to eq([162_507_600_0])
      end

      it "returns the correct contested decision issue ids" do
        expect(subject.request_issues_contested_decision_issue_id).to eq([201])
      end

      it "returns the correct decision dates" do
        expect(subject.request_issues_decision_date).to eq(["2023-07-01"])
      end

      it "returns the correct ineligible due to ids" do
        expect(subject.request_issues_ineligible_due_to_id).to eq([301])
      end

      it "returns the correct ineligible reasons" do
        expect(subject.request_issues_ineligible_reason).to eq(["duplicate"])
      end

      it "returns the correct is unidentified values" do
        expect(subject.request_issues_is_unidentified).to eq([false])
      end

      it "returns the correct unidentified issue texts" do
        expect(subject.request_issues_unidentified_issue_text).to eq(["N/A"])
      end

      it "returns the correct nonrating issue categories" do
        expect(subject.request_issues_nonrating_issue_category).to eq(["education"])
      end

      it "returns the correct nonrating issue descriptions" do
        expect(subject.request_issues_nonrating_issue_description).to eq(["Chapter 35 benefits"])
      end

      it "returns the correct nonrating issue bgs ids" do
        expect(subject.request_issues_nonrating_issue_bgs_id).to eq(["BGS123"])
      end

      it "returns the correct nonrating issue bgs sources" do
        expect(subject.request_issues_nonrating_issue_bgs_source).to eq(["source"])
      end

      it "returns the correct ramp claim ids" do
        expect(subject.request_issues_ramp_claim_id).to eq(["RAMP123"])
      end

      it "returns the correct rating issue associated at times" do
        expect(subject.request_issues_rating_issue_associated_at).to eq([162_507_600_0])
      end

      it "returns the correct untimely exemptions" do
        expect(subject.request_issues_untimely_exemption).to eq([false])
      end

      it "returns the correct untimely exemption notes" do
        expect(subject.request_issues_untimely_exemption_notes).to eq(["N/A"])
      end

      it "returns the correct vacols ids" do
        expect(subject.request_issues_vacols_id).to eq(["VAC123"])
      end

      it "returns the correct vacols sequence ids" do
        expect(subject.request_issues_vacols_sequence_id).to eq([123])
      end

      it "returns the correct veteran participant ids" do
        expect(subject.request_issues_veteran_participant_id).to eq(["VET123"])
      end
    end
  end
end
