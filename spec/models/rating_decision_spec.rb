# frozen_string_literal: true

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
  let(:converted_begin_date) { begin_date + 2.days }
  let(:disability_id) { "5678" }
  let(:disability_date) { profile_date }
  let(:rating_issue_reference_id) { "123" }
  let(:original_denial_date) { promulgation_date - 7 }

  describe ".deserialize" do
    subject { described_class.deserialize(rating_decision.serialize) }

    let(:rating_decision) do
      described_class.new(
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        rating_sequence_number: "1234",
        rating_issue_reference_id: rating_issue_reference_id,
        disability_id: disability_id,
        disability_date: disability_date,
        diagnostic_text: "tinnitus",
        diagnostic_code: "6260",
        begin_date: begin_date,
        participant_id: participant_id,
        benefit_type: :compensation
      )
    end

    it { is_expected.to be_a(described_class) }
  end

  describe ".from_bgs_disability" do
    subject { described_class.from_bgs_disability(rating, bgs_record) }

    let(:decision_type_name) { "Service Connected" }

    let(:associated_claims) do
      [
        { clm_id: "abc123", bnft_clm_tc: "040SCR" },
        { clm_id: "dcf345", bnft_clm_tc: "154IVMC9PMC" }
      ]
    end

    let!(:rating) do
      Generators::PromulgatedRating.build(
        participant_id: participant_id,
        promulgation_date: promulgation_date,
        profile_date: profile_date,
        associated_claims: associated_claims
      )
    end

    let(:bgs_record) do
      {
        decn_tn: decision_type_name,
        dis_sn: disability_id,
        dis_dt: disability_date,
        orig_denial_dt: original_denial_date,
        disability_evaluations: {
          begin_dt: begin_date,
          conv_begin_dt: converted_begin_date,
          dgnstc_tc: "6260",
          dgnstc_tn: "Tinnitus",
          dgnstc_txt: "tinnitus",
          prfl_dt: profile_date,
          rating_sn: "227606458",
          rba_issue_id: rating_issue_reference_id
        }
      }
    end

    it { is_expected.to be_a(described_class) }

    it do
      is_expected.to have_attributes(
        type_name: decision_type_name,
        rating_sequence_number: "227606458",
        rating_issue_reference_id: rating_issue_reference_id,
        disability_id: disability_id,
        diagnostic_text: "tinnitus",
        diagnostic_type: "Tinnitus",
        diagnostic_code: "6260",
        begin_date: begin_date,
        profile_date: profile_date,
        participant_id: rating.participant_id,
        benefit_type: :pension
      )
    end

    context "with multiple disability evaluations" do
      let(:bgs_record) do
        {
          decn_tn: decision_type_name,
          dis_dt: 1.year.ago,
          dis_sn: disability_id,
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

    describe "#decision_text" do
      context "Not Service Connected" do
        let(:decision_type_name) { "Not Service Connected" }

        it "returns formatted diagnosis statement" do
          expect(subject.decision_text).to eq("Tinnitus (tinnitus) is denied.")
        end
      end

      context "Service Connected" do
        let(:decision_type_name) { "Service Connected" }

        it "returns formatted diagnosis statement" do
          expect(subject.decision_text).to eq("Tinnitus (tinnitus) is granted.")
        end
      end
    end

    describe "#contestable?" do
      subject { described_class.from_bgs_disability(rating, bgs_record).contestable? }

      context "rating_issue? is true" do
        it { is_expected.to eq(false) }
      end

      context "rating_issue? is false" do
        let(:rating_issue_reference_id) { nil }

        context "promulgation date and original_denial_date are close" do
          it { is_expected.to eq(true) }
        end

        context "promulgation date, profile date and disability_date are not close" do
          let(:disability_date) { promulgation_date + 6.months }

          it { is_expected.to eq(true) }
        end

        context "profile date and disability date are close, promulgation date is not close" do
          let(:promulgation_date) { disability_date + 6.months }

          it { is_expected.to eq(true) }
        end

        context "profile date is near original_denial_date but not promulgation date" do
          let(:original_denial_date) { promulgation_date - 6.months }
          let(:profile_date) { promulgation_date - 6.months + 3.days }

          it { is_expected.to eq(true) }
        end

        context "original_denial_date is pre-2005, disability date is near promulgation date" do
          let(:original_denial_date) { Time.utc(2004, 1, 1, 12, 0, 0) }
          let(:disability_date) { promulgation_date - 7.days }

          it { is_expected.to eq(true) }
        end
      end
    end

    describe "#effective_date" do
      context "decision is not a rating issue" do
        let(:rating_issue_reference_id) { nil }
        let(:original_denial_date) { Time.zone.today }
        let(:begin_date) { Time.zone.tomorrow }

        it "prefers the original_denial_date as the oldest date" do
          expect(subject.effective_date).to eq(original_denial_date)
        end

        context "original_denial_date is nil" do
          let(:original_denial_date) { nil }

          it "defaults to begin_date" do
            expect(subject.effective_date).to eq(begin_date)
          end
        end
      end
    end

    describe "#decision_date" do
      context "decision is a rating issue" do
        let(:rating_issue_reference_id) { "123" }

        it "uses the promulgation_date if the decision is a rating issue" do
          expect(subject.decision_date).to eq(promulgation_date)
        end
      end

      context "decision is not a rating issue" do
        let(:rating_issue_reference_id) { nil }
        let(:original_denial_date) { Time.zone.today }
        let(:begin_date) { Time.zone.tomorrow }

        it "uses the promulgation_date" do
          expect(subject.decision_date).to eq(promulgation_date)
        end
      end
    end

    describe "#reference_id" do
      it "uses the disability id" do
        expect(subject.reference_id).to eq(disability_id)
      end
    end
  end
end
