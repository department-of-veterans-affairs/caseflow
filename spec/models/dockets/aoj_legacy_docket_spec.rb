# frozen_string_literal: true

describe AojLegacyDocket do
  before do
    create(:case_distribution_lever, :request_more_cases_minimum)
    create(:case_distribution_lever, :nod_adjustment)
    create(:case_distribution_lever, :disable_legacy_non_priority)
    create(:case_distribution_lever, :disable_legacy_priority)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :aoj_cavc_affinity_days)
    create(:case_distribution_lever, :aoj_aod_affinity_days)
    create(:case_distribution_lever, :aoj_affinity_days)
  end

  let(:docket) do
    AojLegacyDocket.new
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
    it "calls AojAppealRepository.genpop_priority_count" do
      expect(AojAppealRepository).to receive(:genpop_priority_count)
      subject.genpop_priority_count
    end
  end

  context "#ready_priority_appeal_ids" do
    it "calls AojAppealRepository.priority_ready_appeal_vacols_ids" do
      expect(AojAppealRepository).to receive(:priority_ready_appeal_vacols_ids)
      subject.ready_priority_appeal_ids
    end
  end

  context "#count" do
    before do
      allow(LegacyAppeal.aoj_appeal_repository).to receive(:docket_counts_by_priority_and_readiness)
        .and_return(counts_by_priority_and_readiness)
    end

    it "correctly aggregates the docket counts" do
      expect(docket.count).to eq(15)
      expect(docket.count(ready: true)).to eq(5)
      expect(docket.count(priority: false)).to eq(12)
      expect(docket.count(ready: false, priority: true)).to eq(2)
    end
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
    subject { AojLegacyDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(judge, 3) }

    it "returns the receipt_date(BFD19) field of the oldest legacy priority appeals ready for distribution" do
      appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
      expect(subject).to eq([appeal.bfd19])
    end
  end

  context "#age_of_n_oldest_nonpriority_appeals_available_to_judge" do
    let(:judge) { create(:user, :with_vacols_judge_record) }
    subject { AojLegacyDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, 3) }

    it "returns the receipt_date(BFD19) field of the oldest legacy nonpriority appeals ready for distribution" do
      appeal = create_nonpriority_distributable_legacy_appeal_not_tied_to_judge
      expect(subject).to eq([appeal.bfd19])
    end
  end

  context "#age_of_oldest_priority_appeal" do
    context "use_by_docket_date is true" do
      before { FeatureToggle.enable!(:acd_distribute_by_docket_date) }
      after { FeatureToggle.disable!(:acd_distribute_by_docket_date) }
      subject { AojLegacyDocket.new.age_of_oldest_priority_appeal }
      it "returns the receipt_date(BFD19) field of the oldest legacy priority appeals ready for distribution" do
        appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
        expect(subject).to eq(appeal.bfd19.to_date)
      end
    end

    context "use by_docket_date is false" do
      subject { AojLegacyDocket.new.age_of_oldest_priority_appeal }
      it "returns the receipt_date(BFDLOOUT) field of the oldest legacy priority appeals ready for distribution" do
        appeal = create_priority_distributable_legacy_appeal_not_tied_to_judge
        expect(subject).to eq(appeal.bfdloout)
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
      let!(:some_cases) { create_list(:case, 2, :type_post_remand) }

      # AojAppealRepository doesn't do much but call VACOLS::AojCaseDocket.distribute_appeals,
      # for which we have good coverage. Just unit-test our part here:
      it "uses AojAppealRepository's distribute_priority_appeals method and returns VACOLS cases" do
        expect(docket).to receive(:should_distribute?)
          .with(distribution, genpop: genpop, style: style)
          .and_return(true)
        expect(AojAppealRepository).to receive(:distribute_priority_appeals)
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
        expect(AojAppealRepository).not_to receive(:distribute_nonpriority_appeals)
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

      it "calls AojAppealRepository.distribute_nonpriority_appeals and returns cases" do
        expect(AojAppealRepository).to receive(:distribute_nonpriority_appeals)
          .with(judge, genpop, range, limit, bust_backlog)
          .and_return(two_cases_as_hashes)

        expect(subject.size).to eq 2
      end
    end
  end

  context "#affinity_date_count" do
    before do
      create_priority_distributable_legacy_appeal_not_tied_to_judge
      create_aoj_aod_cavc_ready_priority_case_1
      create_aoj_aod_cavc_ready_priority_case_2
      create_aoj_cavc_ready_priority_case
      create_nonpriority_aoj_ready_case
      create_nonpriority_distributable_legacy_appeal_not_tied_to_judge("123456")
      create_nonpriority_distributable_legacy_appeal_not_tied_to_judge("123457")
      create_nonpriority_distributable_legacy_appeal_not_tied_to_judge("123458")
    end

    context "when priority is true" do
      context "with in window affinity" do
        it "returns affinity date count" do
          expect(docket.affinity_date_count(true, true)).to eq(2)
        end
      end

      context "with out in window affinity" do
        it "returns affinity date count" do
          expect(docket.affinity_date_count(false, true)).to eq(2)
        end
      end
    end

    context "when priority is false" do
      context "with in window affinity" do
        it "returns affinity date count" do
          expect(docket.affinity_date_count(true, false)).to eq(1)
        end
      end

      context "with out in window affinity" do
        it "returns affinity date count" do
          expect(docket.affinity_date_count(false, false)).to eq(3)
        end
      end
    end
  end
  # {priority out of window}
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

  # {nonpriority out of window}
  def create_nonpriority_distributable_legacy_appeal_not_tied_to_judge(bfkey = "12345")
    create(
      :case,
      bfkey: bfkey,
      bfd19: 1.year.ago,
      bfac: "3",
      bfmpro: "ACT",
      bfcurloc: "81",
      bfdloout: 3.days.ago
    )
  end

  # {nonpriority in window}
  def create_nonpriority_aoj_ready_case
    create(
      :legacy_aoj_appeal,
      affinity_start_date: 2.days.ago,
      tied_to: false,
      bfkey: "122222",
      bfd19: 1.year.ago,
      bfac: "3",
      bfmpro: "ACT",
      bfcurloc: "81",
      bfdloout: 3.days.ago
    )
  end

  # {priority in window}
  def create_aoj_aod_cavc_ready_priority_case_1
    create(:legacy_aoj_appeal,
           :aod,
           affinity_start_date: 1.day.ago,
           cavc: true,
           bfd19: 11.months.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago)
  end

  # {priority out of window}
  def create_aoj_aod_cavc_ready_priority_case_2
    create(:legacy_aoj_appeal,
           :aod,
           affinity_start_date: 2.months.ago,
           cavc: true,
           bfd19: 11.months.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago)
  end

  # {priority out of window}
  def create_aoj_cavc_ready_priority_case
    create(:legacy_aoj_appeal,
           affinity_start_date: 1.month.ago,
           cavc: true,
           bfd19: 11.months.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago)
  end
end
