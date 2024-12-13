# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DecisionReviewCompleted::DecisionReviewCompletedIssueParser do
  let(:issue_data) do
    {
      decision_review_issue_id: 1,
      benefit_type: "compensation",
      contested_decision_issue_id: 201,
      contested_issue_description: "Service connection for PTSD",
      contention_reference_id: 7_905_752,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_profile_date: 1_625_076_000,
      contested_rating_issue_reference_id: "REF9411",
      decision_date: 19_568,
      ineligible_due_to_id: 301,
      ineligible_reason: nil,
      is_unidentified: false,
      unidentified_issue_text: nil,
      nonrating_issue_category: "Accrued Benefits",
      nonrating_issue_description: "Chapter 35 benefits",
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      vacols_id: "VAC123",
      vacols_sequence_id: nil,
      closed_at: 1_625_151_600,
      closed_status: "withdrawn",
      contested_rating_issue_diagnostic_code: "9411",
      ramp_claim_id: "RAMP123",
      rating_issue_associated_at: 1_625_076_000,
      nonrating_issue_bgs_id: "13",
      nonrating_issue_bgs_source: "CORP_AWARD_ATTORNEY_FEE",
      type: "RequestIssue",
      original_caseflow_request_issue_id: 679,
      veteran_participant_id: "1826209",
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
    }
  end

  subject { described_class.new(issue_data) }

  describe "#ri_reference_id" do
    it "returns the decision_review_issue_id" do
      expect(subject.ri_reference_id).to eq(1)
    end
  end

  describe "#ri_benefit_type" do
    it "returns the benefit_type" do
      expect(subject.ri_benefit_type).to eq("compensation")
    end
  end

  describe "#ri_closed_at" do
    it "converts closed_at from milliseconds to datetime" do
      expect(subject.ri_closed_at).to eq(Time.at(1_625_151_600 / 1000).utc)
    end
  end

  describe "#ri_closed_status" do
    it "returns the closed_status" do
      expect(subject.ri_closed_status).to eq("withdrawn")
    end
  end

  describe "#ri_contested_issue_description" do
    it "returns the contested_issue_description" do
      expect(subject.ri_contested_issue_description).to eq("Service connection for PTSD")
    end
  end

  describe "#ri_contention_reference_id" do
    it "returns the contention_reference_id" do
      expect(subject.ri_contention_reference_id).to eq(7_905_752)
    end
  end

  describe "#ri_contested_rating_issue_diagnostic_code" do
    it "returns the contested_rating_issue_diagnostic_code" do
      expect(subject.ri_contested_rating_issue_diagnostic_code).to eq("9411")
    end
  end

  describe "#ri_contested_rating_decision_reference_id" do
    it "returns the contested_rating_decision_reference_id" do
      expect(subject.ri_contested_rating_decision_reference_id).to be_nil
    end
  end

  describe "#ri_contested_rating_issue_profile_date" do
    it "returns the contested_rating_issue_profile_date as timestamp" do
      expect(subject.ri_contested_rating_issue_profile_date).to eq(1_625_076_000)
    end
  end

  describe "#ri_contested_rating_issue_reference_id" do
    it "returns the contested_rating_issue_reference_id" do
      expect(subject.ri_contested_rating_issue_reference_id).to eq("REF9411")
    end
  end

  describe "#ri_contested_decision_issue_id" do
    it "returns the contested_decision_issue_id" do
      expect(subject.ri_contested_decision_issue_id).to eq(201)
    end
  end

  describe "#ri_decision_date" do
    it "returns the decision_date as logical date" do
      expect(subject.ri_decision_date).to eq(Date.new(2023, 7, 30))
    end
  end

  describe "#ri_ineligible_due_to_id" do
    it "returns the ineligible_due_to_id" do
      expect(subject.ri_ineligible_due_to_id).to eq(301)
    end
  end

  describe "#ri_ineligible_reason" do
    it "returns the ineligible_reason" do
      expect(subject.ri_ineligible_reason).to be_nil
    end
  end

  describe "#ri_is_unidentified" do
    it "returns the is_unidentified" do
      expect(subject.ri_is_unidentified).to be false
    end
  end

  describe "#ri_unidentified_issue_text" do
    it "returns the unidentified_issue_text" do
      expect(subject.ri_unidentified_issue_text).to be_nil
    end
  end

  describe "#ri_nonrating_issue_category" do
    it "returns the nonrating_issue_category" do
      expect(subject.ri_nonrating_issue_category).to eq("Accrued Benefits")
    end
  end

  describe "#ri_nonrating_issue_description" do
    it "returns the nonrating_issue_description" do
      expect(subject.ri_nonrating_issue_description).to eq("Chapter 35 benefits")
    end
  end

  describe "#ri_nonrating_issue_bgs_id" do
    it "returns the nonrating_issue_bgs_id" do
      expect(subject.ri_nonrating_issue_bgs_id).to eq("13")
    end
  end

  describe "#ri_nonrating_issue_bgs_source" do
    it "returns the nonrating_issue_bgs_source" do
      expect(subject.ri_nonrating_issue_bgs_source).to eq("CORP_AWARD_ATTORNEY_FEE")
    end
  end

  describe "#ri_ramp_claim_id" do
    it "returns the ramp_claim_id" do
      expect(subject.ri_ramp_claim_id).to eq("RAMP123")
    end
  end

  describe "#ri_rating_issue_associated_at" do
    it "converts rating_issue_associated_at from milliseconds to datetime" do
      expect(subject.ri_rating_issue_associated_at).to eq(Time.at(1_625_076_000 / 1000).utc)
    end
  end

  describe "#ri_untimely_exemption" do
    it "returns the untimely_exemption" do
      expect(subject.ri_untimely_exemption).to be_nil
    end
  end

  describe "#ri_untimely_exemption_notes" do
    it "returns the untimely_exemption_notes" do
      expect(subject.ri_untimely_exemption_notes).to be_nil
    end
  end

  describe "#ri_vacols_id" do
    it "returns the vacols_id" do
      expect(subject.ri_vacols_id).to eq("VAC123")
    end
  end

  describe "#ri_vacols_sequence_id" do
    it "returns the vacols_sequence_id" do
      expect(subject.ri_vacols_sequence_id).to be_nil
    end
  end

  describe "#ri_type" do
    it "returns the type" do
      expect(subject.ri_type).to eq("RequestIssue")
    end
  end

  describe "#original_caseflow_request_issue_id" do
    it "returns the original caseflow request issue id" do
      expect(subject.ri_original_caseflow_request_issue_id).to eq(679)
    end
  end

  describe "#ri_veteran_participant_id" do
    it "returns the veteran_participant_id" do
      expect(subject.ri_veteran_participant_id).to eq("1826209")
    end
  end

  describe "parsed decision_issue internals" do
    it "parse whole decision_issue" do
      expect(subject.decision_issue).to eq(
        {
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
      )
    end

    it "parse decision_issue_benefit_type" do
      expect(subject.decision_issue_benefit_type).to eq("compensation")
    end

    it "parse decision_issue_contention_reference_id" do
      expect(subject.decision_issue_contention_reference_id).to eq(7_905_752)
    end

    it "parse decision_issue_decision_text" do
      expect(subject.decision_issue_decision_text).to eq("service connected")
    end

    it "parse decision_issue_description" do
      expect(subject.decision_issue_description).to eq(nil)
    end

    it "parse decision_issue_diagnostic_code" do
      expect(subject.decision_issue_diagnostic_code).to eq(nil)
    end

    it "parse decision_issue_disposition" do
      expect(subject.decision_issue_disposition).to eq("Granted")
    end

    it "parse decision_issue_end_product_last_action_date" do
      expect(subject.decision_issue_end_product_last_action_date).to eq(19_594)
    end

    it "parse decision_issue_participant_id" do
      expect(subject.decision_issue_participant_id).to eq("1826209")
    end

    it "parse decision_issue_percent_number" do
      expect(subject.decision_issue_percent_number).to eq("50")
    end

    it "parse decision_issue_rating_issue_reference_id" do
      expect(subject.decision_issue_rating_issue_reference_id).to eq(nil)
    end

    it "parse decision_issue_rating_promulgation_date" do
      expect(subject.decision_issue_rating_promulgation_date).to eq(nil)
    end

    it "parse decision_issue_subject_text" do
      expect(subject.decision_issue_subject_text).to eq("This broadcast may not be reproduced")
    end
  end

  context "when attributes use .presence and values are empty strings" do
    let(:empty_issue_data) do
      issue_data.merge(
        benefit_type: "",
        contested_issue_description: "",
        contested_rating_issue_diagnostic_code: "",
        contested_rating_decision_reference_id: "",
        contested_rating_issue_profile_date: "",
        contested_rating_issue_reference_id: "",
        ineligible_reason: "",
        unidentified_issue_text: "",
        nonrating_issue_category: "",
        nonrating_issue_description: "",
        nonrating_issue_bgs_id: "",
        nonrating_issue_bgs_source: "",
        ramp_claim_id: "",
        untimely_exemption_notes: "",
        vacols_id: "",
        veteran_participant_id: "",
        type: ""
      )
    end

    subject { described_class.new(empty_issue_data) }

    it "returns nil for benefit_type if the value is an empty string" do
      expect(subject.ri_benefit_type).to be_nil
    end

    it "returns nil for contested_issue_description if the value is an empty string" do
      expect(subject.ri_contested_issue_description).to be_nil
    end

    it "returns nil for contested_rating_issue_diagnostic_code if the value is an empty string" do
      expect(subject.ri_contested_rating_issue_diagnostic_code).to be_nil
    end

    it "returns nil for contested_rating_decision_reference_id if the value is an empty string" do
      expect(subject.ri_contested_rating_decision_reference_id).to be_nil
    end

    it "returns nil for contested_rating_issue_profile_date if the value is an empty string" do
      expect(subject.ri_contested_rating_issue_profile_date).to be_nil
    end

    it "returns nil for contested_rating_issue_reference_id if the value is an empty string" do
      expect(subject.ri_contested_rating_issue_reference_id).to be_nil
    end

    it "returns nil for ineligible_reason if the value is an empty string" do
      expect(subject.ri_ineligible_reason).to be_nil
    end

    it "returns nil for unidentified_issue_text if the value is an empty string" do
      expect(subject.ri_unidentified_issue_text).to be_nil
    end

    it "returns nil for nonrating_issue_category if the value is an empty string" do
      expect(subject.ri_nonrating_issue_category).to be_nil
    end

    it "returns nil for nonrating_issue_description if the value is an empty string" do
      expect(subject.ri_nonrating_issue_description).to be_nil
    end

    it "returns nil for nonrating_issue_bgs_id if the value is an empty string" do
      expect(subject.ri_nonrating_issue_bgs_id).to be_nil
    end

    it "returns nil for nonrating_issue_bgs_source if the value is an empty string" do
      expect(subject.ri_nonrating_issue_bgs_source).to be_nil
    end

    it "returns nil for ramp_claim_id if the value is an empty string" do
      expect(subject.ri_ramp_claim_id).to be_nil
    end

    it "returns nil for untimely_exemption_notes if the value is an empty string" do
      expect(subject.ri_untimely_exemption_notes).to be_nil
    end

    it "returns nil for vacols_id if the value is an empty string" do
      expect(subject.ri_vacols_id).to be_nil
    end

    it "returns nil for type if the value is an empty string" do
      expect(subject.ri_type).to be_nil
    end
  end
end
