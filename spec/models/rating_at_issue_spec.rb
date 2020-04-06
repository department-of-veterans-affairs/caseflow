# frozen_string_literal: true

describe RatingAtIssue do
  before { FeatureToggle.enable!(:ratings_at_issue) }
  after { FeatureToggle.disable!(:ratings_at_issue) }

  let(:disability_sn) { "1234" }
  let(:diagnostic_code) { "7611" }
  let(:reference_id) { "1555" }
  let(:latest_disability_date) { Time.zone.today - 6.days }
  let(:claim_type_code) { "030HLRRPMC" }
  let(:profile_date) { Time.zone.today - 5.days }
  let(:promulgation_date) { Time.zone.today - 4.days }
  let(:participant_id) { "participant_id" }
  let(:rating_sequence_number) { "rating_sn" }

  let(:issue_data) do
    {
      rba_issue: [
        {
          rba_issue_id: reference_id,
          decn_txt: "Left knee granted",
          dis_sn: disability_sn
        }
      ]
    }
  end

  let(:disability_data) do
    {
      disability: [{
        dis_sn: disability_sn,
        decn_tn: "Service Connected",
        dis_dt: Time.zone.today - 6.days,
        dis_sn: disability_sn,
        disability_evaluation: [
          {
            dgnstc_tc: diagnostic_code,
            dgnstc_txt: "Diagnostic text",
            dgnstc_tn: "Diagnostic type name",
            dis_dt: latest_disability_date,
            begin_dt: latest_disability_date,
            conv_begin_dt: latest_disability_date,
            dis_sn: disability_sn,
            rating_sn: rating_sequence_number,
            rba_issue_id: reference_id
          },
          {
            dgnstc_tc: "9999",
            dis_dt: Time.zone.today - 7.days, # older evaluation
            dis_sn: disability_sn
          }
        ]
      }]
    }
  end

  let(:claim_data) do
    {
      rba_claim: {
        bnft_clm_tc: claim_type_code,
        clm_id: reference_id
      }
    }
  end

  let(:bgs_record) do
    {
      prfl_dt: profile_date,
      ptcpnt_vet_id: participant_id,
      prmlgn_dt: promulgation_date,
      rba_issue_list: issue_data,
      disability_list: disability_data,
      rba_claim_list: claim_data
    }
  end

  context ".fetch_all" do
    let(:receipt_date) { Time.zone.today - 50.years }

    subject { RatingAtIssue.fetch_all("DRAYMOND") }

    let!(:rating) do
      Generators::RatingAtIssue.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 370.days
      )
    end

    let!(:untimely_rating) do
      Generators::RatingAtIssue.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 100.years
      )
    end

    it "returns rating objects for all ratings" do
      expect(subject.count).to eq(2)
    end

    context "on NoRatingsExistForVeteran error" do
      subject { RatingAtIssue.fetch_all("FOOBAR") }

      it "returns empty array" do
        expect(subject.count).to eq(0)
      end
    end
  end

  context ".from_bgs_hash" do
    subject { RatingAtIssue.from_bgs_hash(bgs_record) }

    it { is_expected.to be_a(Rating) }

    it do
      is_expected.to have_attributes(
        participant_id: participant_id,
        profile_date: profile_date,
        promulgation_date: promulgation_date
      )
    end

    it "is expected to have a rating profile" do
      expect(subject.rating_profile).to_not be_nil
    end

    it "is expected to have correct issue data" do
      expect(subject.issues.count).to eq(1)

      issue = subject.issues.first

      expect(issue).to be_a(RatingIssue)

      # This should be the code from the most recent issue
      expect(issue.diagnostic_code).to eq(diagnostic_code)
      expect(issue.reference_id).to eq(reference_id)
    end

    it "is expected to have correct associated end product data" do
      end_product = subject.associated_end_products.first

      expect(end_product.claim_id).to eq reference_id
      expect(end_product.claim_type_code).to eq claim_type_code
    end

    it "is expected to identify pension claims" do
      expect(subject.pension?).to eq true
    end

    context "when contestable_rating_decisions is enabled" do
      before { FeatureToggle.enable!(:contestable_rating_decisions) }
      after { FeatureToggle.disable!(:contestable_rating_decisions) }

      it "is expected to have correct rating decision data" do
        decision = subject.decisions.first

        expect(decision).to be_a(RatingDecision)
        expect(decision).to have_attributes(
          type_name: "Service Connected",
          rating_sequence_number: rating_sequence_number,
          rating_issue_reference_id: reference_id,
          disability_date: latest_disability_date,
          disability_id: disability_sn,
          diagnostic_text: "Diagnostic text",
          diagnostic_type: "Diagnostic type name",
          diagnostic_code: diagnostic_code,
          begin_date: latest_disability_date,
          converted_begin_date: latest_disability_date,
          original_denial_date: nil,
          original_denial_indicator: nil,
          previous_rating_sequence_number: nil,
          profile_date: profile_date,
          promulgation_date: promulgation_date,
          participant_id: participant_id,
          benefit_type: :pension
        )
      end
    end
  end
end
