# frozen_string_literal: true

require "ostruct"

describe Events::DecisionReviewCreated::DecisionReviewCreatedIssueParser do
  let(:payload) do
    {
      benefit_type: "compensation",
      contested_issue_description: nil,
      contention_reference_id: 7_905_752,
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_profile_date: nil,
      contested_rating_issue_reference_id: nil,
      contested_decision_issue_id: nil,
      decision_date: 19_568,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: false,
      unidentified_issue_text: nil,
      nonrating_issue_category: "Accrued Benefits",
      nonrating_issue_description: "The user entered description if the issue is a nonrating issue",
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      vacols_id: nil,
      vacols_sequence_id: nil,
      closed_at: nil,
      closed_status: nil,
      contested_rating_issue_diagnostic_code: nil,
      ramp_claim_id: nil,
      rating_issue_associated_at: nil,
      nonrating_issue_bgs_id: "13",
      nonrating_issue_bgs_source: "Test Source"
    }
  end

  subject { described_class.new(payload) }

  it "parses benefit_type correctly" do
    expect(subject.ri_benefit_type).to eq("compensation")
  end

  it "parses contested_issue_description as nil when absent" do
    expect(subject.ri_contested_issue_description).to be_nil
  end

  it "parses contention_reference_id correctly" do
    expect(subject.ri_contention_reference_id).to eq(7_905_752)
  end

  it "parses contested_rating_decision_reference_id as nil when absent" do
    expect(subject.ri_contested_rating_decision_reference_id).to be_nil
  end

  it "parses contested_rating_issue_profile_date as nil when absent" do
    expect(subject.ri_contested_rating_issue_profile_date).to be_nil
  end

  it "parses contested_rating_issue_reference_id as nil when absent" do
    expect(subject.ri_contested_rating_issue_reference_id).to be_nil
  end

  it "parses contested_decision_issue_id correctly" do
    expect(subject.ri_contested_decision_issue_id).to be_nil
  end

  it "parses decision_date correctly using logical_date_converter" do
    expect(subject.ri_decision_date).to eq(subject.logical_date_converter(19_568))
  end

  it "parses ineligible_due_to_id correctly" do
    expect(subject.ri_ineligible_due_to_id).to be_nil
  end

  it "parses ineligible_reason as nil when absent" do
    expect(subject.ri_ineligible_reason).to be_nil
  end

  it "parses is_unidentified correctly" do
    expect(subject.ri_is_unidentified).to eq(false)
  end

  it "parses unidentified_issue_text as nil when absent" do
    expect(subject.ri_unidentified_issue_text).to be_nil
  end

  it "parses nonrating_issue_category correctly" do
    expect(subject.ri_nonrating_issue_category).to eq("Accrued Benefits")
  end

  it "parses nonrating_issue_description correctly" do
    expect(subject.ri_nonrating_issue_description).to eq("The user entered description if the issue is a nonrating issue")
  end

  it "parses untimely_exemption correctly" do
    expect(subject.ri_untimely_exemption).to be_nil
  end

  it "parses untimely_exemption_notes as nil when absent" do
    expect(subject.ri_untimely_exemption_notes).to be_nil
  end

  it "parses vacols_id as nil when absent" do
    expect(subject.ri_vacols_id).to be_nil
  end

  it "parses vacols_sequence_id correctly" do
    expect(subject.ri_vacols_sequence_id).to be_nil
  end

  it "parses closed_at as nil when absent" do
    expect(subject.ri_closed_at).to be_nil
  end

  it "parses closed_status as nil when absent" do
    expect(subject.ri_closed_status).to be_nil
  end

  it "parses contested_rating_issue_diagnostic_code correctly" do
    expect(subject.ri_contested_rating_issue_diagnostic_code).to be_nil
  end

  it "parses ramp_claim_id as nil when absent" do
    expect(subject.ri_ramp_claim_id).to be_nil
  end

  it "parses rating_issue_associated_at as nil when absent" do
    expect(subject.ri_rating_issue_associated_at).to be_nil
  end

  it "parses nonrating_issue_bgs_id correctly" do
    expect(subject.ri_nonrating_issue_bgs_id).to eq("13")
  end

  it "parses nonrating_issue_bgs_source correctly" do
    expect(subject.ri_nonrating_issue_bgs_source).to eq("Test Source")
  end
end
