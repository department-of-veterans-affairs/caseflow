# frozen_string_literal: true

require "rails_helper"

describe RatingDecision do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:profile_date) { Time.zone.today - 40 }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:participant_id) { "1234567" }

  context ".deserialize" do
    subject { described_class.deserialize(rating_decision.serialize) }

    let(:rating_decision) do
      described_class.new(
        profile_date: profile_date,
        rating_sequence_number: "1234",
        disability_id: "5678",
        diagnostic_text: "tinnitus",
        diagnostic_code: "6260",
        disability_date: profile_date + 30.days,
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
        dis_dt: 1.year.ago,
        dis_sn: "67468264",
        disability_evaluations: {
          dgnstc_tc: "6260",
          dgnstc_tn: "Tinnitus",
          dgnstc_txt: "tinnitus",
          prfl_dt: profile_date,
          rating_sn: "227606458",
        }
      }
    end

    it { is_expected.to be_a(described_class) }

    it do
      is_expected.to have_attributes(
        type_name: decision_type_name,
        rating_sequence_number: "227606458",
        disability_id: "67468264",
        diagnostic_text: "tinnitus",
        diagnostic_type: "Tinnitus",
        diagnostic_code: "6260",
        disability_date: 1.year.ago,
        profile_date: profile_date,
        participant_id: rating.participant_id,
        benefit_type: :pension
      )
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
  end
end
