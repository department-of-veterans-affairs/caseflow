# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DecisionReviewCreated::DecisionReviewCreatedIssueParser, type: :service do
  let(:issue_data) do
    {
      decision_review_issue_id: "123",
      benefit_type: "compensation",
      contested_issue_description: "Description",
      contention_reference_id: "456",
      contested_rating_decision_reference_id: "789",
      contested_rating_issue_profile_date: "2023-01-01",
      contested_rating_issue_reference_id: "321",
      contested_decision_issue_id: "654",
      decision_date: "20230101",
      ineligible_due_to_id: "987",
      ineligible_reason: "duplicate_of_rating_issue_in_active_review",
      is_unidentified: false,
      unidentified_issue_text: "Some text",
      nonrating_issue_category: "Category A",
      nonrating_issue_description: "Non-rating issue description",
      untimely_exemption: true,
      untimely_exemption_notes: "Some notes",
      vacols_id: "VAC123",
      vacols_sequence_id: "SEQ456",
      closed_at: 1_683_072_000_000, # Example timestamp
      closed_status: "withdrawn",
      contested_rating_issue_diagnostic_code: "7890",
      ramp_claim_id: "RAMP123",
      rating_issue_associated_at: 1_683_072_000_000, # Example timestamp
      nonrating_issue_bgs_id: "BGS987",
      nonrating_issue_bgs_source: "source"
    }
  end

  let(:parser) { described_class.new(issue_data) }

  describe "#ri_reference_id" do
    it "returns the decision review issue id" do
      expect(parser.ri_reference_id).to eq("123")
    end
  end

  describe "#ri_benefit_type" do
    it "returns the benefit type" do
      expect(parser.ri_benefit_type).to eq("compensation")
    end
  end

  describe "#ri_contested_issue_description" do
    it "returns the contested issue description" do
      expect(parser.ri_contested_issue_description).to eq("Description")
    end
  end

  describe "#ri_contention_reference_id" do
    it "returns the contention reference id" do
      expect(parser.ri_contention_reference_id).to eq("456")
    end
  end

  describe "#ri_contested_rating_decision_reference_id" do
    it "returns the contested rating decision reference id" do
      expect(parser.ri_contested_rating_decision_reference_id).to eq("789")
    end
  end

  describe "#ri_contested_rating_issue_profile_date" do
    it "returns the contested rating issue profile date" do
      expect(parser.ri_contested_rating_issue_profile_date).to eq("2023-01-01")
    end
  end

  describe "#ri_contested_rating_issue_reference_id" do
    it "returns the contested rating issue reference id" do
      expect(parser.ri_contested_rating_issue_reference_id).to eq("321")
    end
  end

  describe "#ri_contested_decision_issue_id" do
    it "returns the contested decision issue id" do
      expect(parser.ri_contested_decision_issue_id).to eq("654")
    end
  end

  describe "#ri_decision_date" do
    it "returns the parsed decision date" do
      allow(parser).to receive(:logical_date_converter).with("20230101").and_return(Date.new(2023, 1, 1))
      expect(parser.ri_decision_date).to eq(Date.new(2023, 1, 1))
    end
  end

  describe "#ri_ineligible_due_to_id" do
    it "returns the ineligible due to id" do
      expect(parser.ri_ineligible_due_to_id).to eq("987")
    end
  end

  describe "#ri_ineligible_reason" do
    it "returns the ineligible reason" do
      expect(parser.ri_ineligible_reason).to eq("duplicate_of_rating_issue_in_active_review")
    end
  end

  describe "#ri_is_unidentified" do
    it "returns the unidentified status" do
      expect(parser.ri_is_unidentified).to eq(false)
    end
  end

  describe "#ri_unidentified_issue_text" do
    it "returns the unidentified issue text" do
      expect(parser.ri_unidentified_issue_text).to eq("Some text")
    end
  end

  describe "#ri_nonrating_issue_category" do
    it "returns the nonrating issue category" do
      expect(parser.ri_nonrating_issue_category).to eq("Category A")
    end
  end

  describe "#ri_nonrating_issue_description" do
    it "returns the nonrating issue description" do
      expect(parser.ri_nonrating_issue_description).to eq("Non-rating issue description")
    end
  end

  describe "#ri_untimely_exemption" do
    it "returns the untimely exemption status" do
      expect(parser.ri_untimely_exemption).to eq(true)
    end
  end

  describe "#ri_untimely_exemption_notes" do
    it "returns the untimely exemption notes" do
      expect(parser.ri_untimely_exemption_notes).to eq("Some notes")
    end
  end

  describe "#ri_vacols_id" do
    it "returns the vacols id" do
      expect(parser.ri_vacols_id).to eq("VAC123")
    end
  end

  describe "#ri_vacols_sequence_id" do
    it "returns the vacols sequence id" do
      expect(parser.ri_vacols_sequence_id).to eq("SEQ456")
    end
  end

  describe "#ri_closed_at" do
    it "returns the closed_at datetime converted from milliseconds" do
      allow(parser).to receive(:convert_milliseconds_to_datetime).with(1_683_072_000_000)
        .and_return(Time.zone.at(1_683_072_000))
      expect(parser.ri_closed_at).to eq(Time.zone.at(1_683_072_000))
    end
  end

  describe "#ri_closed_status" do
    it "returns the closed status" do
      expect(parser.ri_closed_status).to eq("withdrawn")
    end
  end

  describe "#ri_contested_rating_issue_diagnostic_code" do
    it "returns the contested rating issue diagnostic code" do
      expect(parser.ri_contested_rating_issue_diagnostic_code).to eq("7890")
    end
  end

  describe "#ri_ramp_claim_id" do
    it "returns the ramp claim id" do
      expect(parser.ri_ramp_claim_id).to eq("RAMP123")
    end
  end

  describe "#ri_rating_issue_associated_at" do
    it "returns the rating issue associated datetime converted from milliseconds" do
      allow(parser).to receive(:convert_milliseconds_to_datetime)
        .with(1_683_072_000_000).and_return(Time.zone.at(1_683_072_000))
      expect(parser.ri_rating_issue_associated_at).to eq(Time.zone.at(1_683_072_000))
    end
  end

  describe "#ri_nonrating_issue_bgs_id" do
    it "returns the nonrating issue bgs id" do
      expect(parser.ri_nonrating_issue_bgs_id).to eq("BGS987")
    end
  end

  describe "#ri_nonrating_issue_bgs_source" do
    it "returns the nonrating issue bgs source" do
      expect(parser.ri_nonrating_issue_bgs_source).to eq("source")
    end
  end
end
