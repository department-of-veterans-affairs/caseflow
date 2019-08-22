# frozen_string_literal: true

require "rails_helper"

describe RatingDecision do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))

    FeatureToggle.enable!(:contestable_rating_decisions)
  end

  after do
    FeatureToggle.disable!(:contestable_rating_decisions)
  end

  let(:profile_date) { Time.zone.today - 40 }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:participant_id) { "1234567" }
  let(:begin_date) { profile_date + 30.days }

  context ".deserialize" do
    subject { described_class.deserialize(rating_decision.serialize) }

    let(:rating_decision) do
      described_class.new(
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        rating_sequence_number: "1234",
        disability_id: "5678",
        diagnostic_text: "tinnitus",
        diagnostic_code: "6260",
        begin_date: begin_date,
        participant_id: participant_id,
        benefit_type: :compensation
      )
    end

    it { is_expected.to be_a(described_class) }
  end

  context ".from_bgs_disability" do
    subject { described_class.from_bgs_disability(rating, bgs_record) }

    let(:decision_type_name) { "Service Connected" }

    let(:associated_claims) do
      [
        { clm_id: "abc123", bnft_clm_tc: "040SCR" },
        { clm_id: "dcf345", bnft_clm_tc: "154IVMC9PMC" }
      ]
    end

    let!(:rating) do
      Generators::Rating.build(
        participant_id: participant_id,
        promulgation_date: promulgation_date,
        profile_date: profile_date,
        associated_claims: associated_claims
      )
    end

    let(:bgs_record) do
      {
        decn_tn: decision_type_name,
        dis_sn: "67468264",
        disability_evaluations: {
          begin_dt: begin_date,
          dgnstc_tc: "6260",
          dgnstc_tn: "Tinnitus",
          dgnstc_txt: "tinnitus",
          prfl_dt: profile_date,
          rating_sn: "227606458",
          rba_issue_id: "56780000"
        }
      }
    end

    it { is_expected.to be_a(described_class) }

    it do
      is_expected.to have_attributes(
        type_name: decision_type_name,
        rating_sequence_number: "227606458",
        rating_issue_reference_id: "56780000",
        disability_id: "67468264",
        diagnostic_text: "tinnitus",
        diagnostic_type: "Tinnitus",
        diagnostic_code: "6260",
        begin_date: begin_date,
        profile_date: profile_date,
        participant_id: rating.participant_id,
        benefit_type: :pension
      )
    end

    context "with multiple disabilities" do
      let(:bgs_record) do
        {
          decn_tn: decision_type_name,
          dis_dt: 1.year.ago,
          dis_sn: "67468264",
          disability_evaluations: [
            {
              dis_dt: 1.year.ago - 1.day,
              dgnstc_tc: "6260",
              dgnstc_tn: "Tinnitus",
              dgnstc_txt: "tinnitus",
              prfl_dt: profile_date,
              rating_sn: "227606458",
              rba_issue_id: "56780000"
            },
            {
              dis_dt: 1.year.ago,
              dgnstc_tc: "6260",
              dgnstc_tn: "Tinnitus",
              dgnstc_txt: "tinnitus",
              prfl_dt: profile_date,
              rating_sn: "later",
              rba_issue_id: "later"
            }
          ]
        }
      end

      it "prefers latest date" do
        expect(subject).to have_attributes(
          rating_sequence_number: "later", rating_issue_reference_id: "later"
        )
      end
    end

    describe "#service_connected?" do
      it "returns true" do
        expect(subject.service_connected?).to eq(true)
      end

      context "decision type name is Not Service Connected" do
        let(:decision_type_name) { "Not Service Connected" }

        it "returns false" do
          expect(subject.service_connected?).to eq(false)
        end
      end
    end

    describe "#decision_date" do
      it "uses the begin_date if available" do
        expect(subject.decision_date).to eq(begin_date)
      end
    end

    describe "#reference_id" do
      it "uses the disability id" do
        expect(subject.reference_id).to eq("67468264")
      end
    end
  end
end
