# frozen_string_literal: true

describe LegacyDocket do
  let(:docket) do
    LegacyDocket.new
  end

  let(:counts_by_priority_and_readiness) do
    [
      { "n" => 1, "ready" => 1, "priority" => 1 },
      { "n" => 2, "ready" => 0, "priority" => 1 },
      { "n" => 4, "ready" => 1, "priority" => 0 },
      { "n" => 8, "ready" => 0, "priority" => 0 }
    ]
  end

  context "#docket_type" do
    it "is legacy" do
      expect(subject.docket_type).to eq "legacy"
    end
  end

  context "#genpop_priority_count" do
    it "calls AppealRepository.genpop_priority_count" do
      expect(AppealRepository).to receive(:genpop_priority_count)
      subject.genpop_priority_count
    end
  end

  context "#ready_priority_appeal_ids" do
    it "calls AppealRepository.priority_ready_appeal_vacols_ids" do
      expect(AppealRepository).to receive(:priority_ready_appeal_vacols_ids)
      subject.ready_priority_appeal_ids
    end
  end

  context "#count" do
    before do
      allow(LegacyAppeal.repository).to receive(:docket_counts_by_priority_and_readiness)
        .and_return(counts_by_priority_and_readiness)
    end

    it "correctly aggregates the docket counts" do
      expect(docket.count).to eq(15)
      expect(docket.count(ready: true)).to eq(5)
      expect(docket.count(priority: false)).to eq(12)
      expect(docket.count(ready: false, priority: true)).to eq(2)
    end
  end

  context "#weight" do
    subject { docket.weight }

    before do
      allow(LegacyAppeal.repository).to receive(:docket_counts_by_priority_and_readiness)
        .and_return(counts_by_priority_and_readiness)
      allow(LegacyAppeal.repository).to receive(:nod_count).and_return(1)
    end

    it { is_expected.to eq(12.4) }
  end

  context "#oldest_priority_appeals_days_waiting" do
    subject { docket.oldest_priority_appeal_days_waiting }

    context "when there is no oldest priority appeal" do
      it "returns zero" do
        expect(docket).to receive(:age_of_oldest_priority_appeal).and_return(nil)
        expect(subject).to eq 0
      end
    end

    context "when there is an oldest priority appeal" do
      let(:start_time) { Time.zone.local(2020, 1, 1) }
      let(:number_of_days) { 10 }
      let(:end_time) { start_time + number_of_days.days }

      before { Timecop.freeze(end_time) }

      it "returns the age in days" do
        expect(docket).to receive(:age_of_oldest_priority_appeal)
          .and_return(start_time)
          .exactly(2).times

        expect(subject).to eq number_of_days
      end
    end
  end

  context "#age_of_n_oldest_priority_appeals_available_to_judge" do
    let(:judge) { create(:user, :with_vacols_judge_record) }
    subject { LegacyDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(judge, 3) }

    it "returns the receipt_date(BFD19) field of the oldest legacy priority appeals ready for distribution" do
      appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
      expect(subject).to eq([appeal.bfd19])
    end
  end

  context "#age_of_n_oldest_nonpriority_appeals_available_to_judge" do
    let(:judge) { create(:user, :with_vacols_judge_record) }
    subject { LegacyDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, 3) }

    it "returns the receipt_date(BFD19) field of the oldest legacy nonpriority appeals ready for distribution" do
      appeal = create_nonpriority_distributable_legacy_appeal_not_tied_to_judge
      expect(subject).to eq([appeal.bfd19])
    end
  end

  context "#age_of_oldest_priority_appeal" do
    context "use_by_docket_date is true" do
      before { FeatureToggle.enable!(:acd_distribute_by_docket_date) }
      after { FeatureToggle.disable!(:acd_distribute_by_docket_date) }
      subject { LegacyDocket.new.age_of_oldest_priority_appeal }
      it "returns the receipt_date(BFD19) field of the oldest legacy priority appeals ready for distribution" do
        appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
        expect(subject).to eq(appeal.bfd19.to_date)
      end
    end

    context "use by_docket_date is false" do
      subject { LegacyDocket.new.age_of_oldest_priority_appeal }
      it "returns the receipt_date(BFDLOOUT) field of the oldest legacy priority appeals ready for distribution" do
        appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
        expect(subject).to eq(appeal.bfdloout)
      end
    end
  end

  context "#should_distribute?" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { Distribution.create!(judge: judge) }
    let(:style) { "request" }
    let(:genpop) { "any" }

    subject { docket.should_distribute?(distribution, style: style, genpop: genpop) }

    context "with tied cases" do
      let(:genpop) { "not_genpop" }

      it "always returns true" do
        expect(subject).to be_truthy
      end
    end

    context "with genpop cases" do
      let(:genpop) { "any" }
      context "when the JudgeTeam is set AMA only for the relevant type" do
        context "when this is a push distribution" do
          let(:style) { "push" }

          before do
            JudgeTeam.for_judge(judge).update!(ama_only_push: true, ama_only_request: false)
          end

          it "should return false since this is a legacy (non-AMA) docket" do
            expect(subject).to be_falsey
          end
        end

        context "when this is a requested distribution" do
          let(:style) { "request" }

          before do
            JudgeTeam.for_judge(judge).update!(ama_only_push: true, ama_only_request: true)
          end

          it "should return false since this is a legacy (non-AMA) docket" do
            expect(subject).to be_falsey
          end
        end
      end

      context "when the JudgeTeam is not AMA-only" do
        before do
          JudgeTeam.for_judge(judge).update!(ama_only_push: false, ama_only_request: false)
        end

        context "when this is a push distribution" do
          let(:style) { "push" }

          it "should return true" do
            expect(subject).to be_truthy
          end
        end

        context "when this is a requested distribution" do
          let(:style) { "request" }

          it "should return true" do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  context "#distribute_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { Distribution.create!(judge: judge) }
    let(:style) { "request" }
    let(:genpop) { "any" }
    let(:priority) { false }
    let(:limit) { 10 }

    subject { docket.distribute_appeals(distribution, style: style, priority: priority, genpop: genpop, limit: limit) }

    context "when should_distribute? returns false" do
      it "returns an empty array" do
        expect(docket).to receive(:should_distribute?)
          .with(distribution, style: style, genpop: genpop)
          .and_return(false)

        expect(subject).to eq []
      end
    end

    context "when this is a priority distribution" do
      let(:priority) { true }

      it "calls distribute_priority_appeals" do
        expect(docket).to receive(:distribute_priority_appeals)
          .with(distribution, style: style, genpop: genpop, limit: limit)

        subject
      end
    end

    context "when this is a non-priority distribution" do
      let(:priority) { false }

      it "calls distribute_nonpriority_appeals" do
        expect(docket).to receive(:distribute_nonpriority_appeals)
          .with(distribution, style: style, genpop: genpop, limit: limit, range: nil)

        subject
      end
    end
  end

  context "#distribute_priority_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:genpop) { "any" } # this isn't significant here I don't think
    let(:style) { "push" } # ..
    let(:limit) { 1 } # ..
    let(:distribution) { Distribution.create!(judge: judge) }
    subject { docket.distribute_priority_appeals(distribution) }

    context "when should_distribute? returns false, blocking distribution" do
      it "returns an empty array" do
        expect(docket).to receive(:should_distribute?)
          .with(distribution, genpop: genpop, style: style)
          .and_return(false)
        expect(subject).to eq []
        subject
      end
    end

    context "when should_distribute? allows distribution" do
      let!(:some_cases) { create_list(:case, 2) }

      # AppealRepository doesn't do much but call VACOLS::CaseDocket.distribute_appeals,
      # for which we have good coverage. Just unit-test our part here:
      it "uses AppealRepository's distribute_priority_appeals method and returns VACOLS cases" do
        expect(docket).to receive(:should_distribute?)
          .with(distribution, genpop: genpop, style: style)
          .and_return(true)
        expect(AppealRepository).to receive(:distribute_priority_appeals)
          .with(judge, genpop, limit)
          .and_return(some_cases)

        expect(subject.size).to eq some_cases.size
      end
    end
  end

  context "#distribute_nonpriority_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:genpop) { "any" } # this isn't significant here I don't think
    let(:style) { "push" } # ..
    let(:limit) { 1 } # ..
    let(:range) { nil }
    let(:bust_backlog) { false }
    let(:distribution) { Distribution.create!(judge: judge) }
    subject { docket.distribute_nonpriority_appeals(distribution, range: range) }

    context "when should_distribute? returns false, blocking distribution" do
      before do
        expect(docket).to receive(:should_distribute?).and_return(false)
      end

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "when range is zero or less" do
      let(:range) { 0 }
      it "returns an empty array" do
        expect(subject).to eq []
        expect(AppealRepository).not_to receive(:distribute_nonpriority_appeals)
      end
    end

    context "when should_distribute? returns true and range is nil or >= 0" do
      let(:two_cases_as_hashes) do
        cases = create_list(:case, 2)
        i = 0
        cases.map do |kase|
          { bfkey: kase.bfkey, bfdloout: kase.bfdloout, vlj: judge.css_id, docket_index: i += 1 }.stringify_keys
        end
      end

      it "calls AppealRepository.distribute_nonpriority_appeals and returns cases" do
        expect(AppealRepository).to receive(:distribute_nonpriority_appeals)
          .with(judge, genpop, range, limit, bust_backlog)
          .and_return(two_cases_as_hashes)

        expect(subject.size).to eq 2
      end
    end
  end

  def create_priority_distributable_legacy_appeal_not_tied_to_judge
    create(
      :case,
      :aod,
      bfkey: "12345",
      bfd19: 1.year.ago,
      bfac: "3",
      bfmpro: "ACT",
      bfcurloc: "81",
      bfdloout: 3.days.ago
    )
  end

  def create_nonpriority_distributable_legacy_appeal_not_tied_to_judge
    create(
      :case,
      bfkey: "12345",
      bfd19: 1.year.ago,
      bfac: "3",
      bfmpro: "ACT",
      bfcurloc: "81",
      bfdloout: 3.days.ago
    )
  end
end
