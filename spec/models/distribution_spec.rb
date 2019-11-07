# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Distribution, :all_dbs do
  let(:judge) { create(:user) }
  let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
  let(:member_count) { 5 }
  let(:attorneys) { create_list(:user, member_count) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:today) { Time.utc(2019, 1, 1, 12, 0, 0) }

  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(today)
    attorneys.each do |u|
      judge_team.add_user(u)
    end

    # set up a couple of extra judge teams
    2.times do
      team = JudgeTeam.create_for_judge(create(:user))
      create_list(:user, 5).each do |attorney|
        team.add_user(attorney)
      end
    end
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "#distribute!" do
    subject { Distribution.create!(judge: judge) }

    let(:legacy_priority_count) { 14 }

    let!(:legacy_priority_cases) do
      (1..legacy_priority_count).map do |i|
        create(:case,
               :aod,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:legacy_nonpriority_cases) do
      (15..100).map do |i|
        create(:case,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:same_judge_priority_hearings) do
      legacy_priority_cases[0..1].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:same_judge_nonpriority_hearings) do
      legacy_nonpriority_cases[29..33].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:other_judge_hearings) do
      legacy_nonpriority_cases[2..27].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: "1234")
      end
    end

    before do
      allow_any_instance_of(DirectReviewDocket)
        .to receive(:nonpriority_receipts_per_year)
        .and_return(100)

      allow(Docket)
        .to receive(:nonpriority_decisions_per_year)
        .and_return(1000)

      allow_any_instance_of(HearingRequestDocket)
        .to receive(:age_of_n_oldest_priority_appeals)
        .and_return([])

      allow_any_instance_of(HearingRequestDocket)
        .to receive(:distribute_appeals)
        .and_return([])
    end

    let!(:due_direct_review_cases) do
      (0...6).map do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review,
               receipt_date: 11.months.ago,
               target_decision_date: 1.month.from_now)
      end
    end

    let!(:priority_direct_review_case) do
      appeal = create(:appeal,
                      :with_post_intake_tasks,
                      :advanced_on_docket_due_to_age,
                      docket_type: Constants.AMA_DOCKETS.direct_review,
                      receipt_date: 1.month.ago)
      appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: 1.month.ago)
      appeal
    end

    let!(:other_direct_review_cases) do
      (0...20).map do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review,
               receipt_date: 61.days.ago,
               target_decision_date: 304.days.from_now)
      end
    end

    let!(:evidence_submission_cases) do
      (0...43).map do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.evidence_submission)
      end
    end

    let!(:hearing_cases) do
      (0...43).map do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.hearing)
      end
    end

    it "correctly distributes cases" do
      evidence_submission_cases[0...2].each do |appeal|
        appeal.tasks
          .find_by(type: EvidenceSubmissionWindowTask.name)
          .update!(status: :completed)
      end
      subject.distribute!
      expect(subject.valid?).to eq(true)
      expect(subject.status).to eq("completed")
      expect(subject.started_at).to eq(Time.zone.now) # time is frozen so appears zero time elapsed
      expect(subject.errored_at).to be_nil
      expect(subject.completed_at).to eq(Time.zone.now)
      expect(subject.statistics["batch_size"]).to eq(15)
      expect(subject.statistics["total_batch_size"]).to eq(45)
      expect(subject.statistics["priority_count"]).to eq(legacy_priority_count + 1)
      expect(subject.statistics["legacy_proportion"]).to eq(0.4)
      expect(subject.statistics["direct_review_proportion"]).to eq(0.2)
      expect(subject.statistics["evidence_submission_proportion"]).to eq(0.2)
      expect(subject.statistics["hearing_proportion"]).to eq(0.2)
      expect(subject.statistics["pacesetting_direct_review_proportion"]).to eq(0.1)
      expect(subject.statistics["interpolated_minimum_direct_review_proportion"]).to eq(0.067)
      expect(subject.statistics["nonpriority_iterations"]).to be_between(2, 3)
      expect(subject.distributed_cases.count).to eq(15)
      expect(subject.distributed_cases.first.docket).to eq("legacy")
      expect(subject.distributed_cases.first.ready_at).to eq(2.days.ago.beginning_of_day)
      expect(subject.distributed_cases.where(priority: true).count).to eq(5)
      expect(subject.distributed_cases.where(genpop: true).count).to eq(5)
      expect(subject.distributed_cases.where(priority: true, genpop: false).count).to eq(2)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "not_genpop").count).to eq(0)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "any").map(&:docket_index).max).to eq(30)
      expect(subject.distributed_cases.where(priority: true,
                                             docket: Constants.AMA_DOCKETS.direct_review).count).to eq(1)
      expect(subject.distributed_cases.where(docket: "legacy").count).to be >= 8
      expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.direct_review).count).to be >= 3
      expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.evidence_submission).count).to eq(2)
    end

    context "when a nonpriority legacy case re-distribtution is attempted" do
      before do
        @raven_called = false
        distribution = create(:distribution, judge: judge)
        legacy_case = legacy_nonpriority_cases.first
        distribution.distributed_cases.create(
          case_id: legacy_case.bfkey,
          priority: false,
          docket: "legacy",
          ready_at: VacolsHelper.normalize_vacols_datetime(legacy_case.bfdloout),
          docket_index: "123",
          genpop: false,
          genpop_query: "foobar"
        )
        distribution.update!(status: "completed", completed_at: today)
        allow(Raven).to receive(:capture_exception) { @raven_called = true }
      end

      it "does not create a duplicate distributed_case" do
        subject.distribute!
        expect(subject.valid?).to eq(true)
        expect(subject.error?).to eq(false)
        expect(@raven_called).to eq(true)
      end
    end

    context "when a priority legacy case re-distribtution is attempted" do
      before do
        @raven_called = false
        distribution = create(:distribution, judge: judge)
        legacy_case = legacy_priority_cases.last
        distribution.distributed_cases.create(
          case_id: legacy_case.bfkey,
          priority: true,
          docket: "legacy",
          ready_at: VacolsHelper.normalize_vacols_datetime(legacy_case.bfdloout),
          docket_index: "123",
          genpop: false,
          genpop_query: "foobar"
        )
        distribution.update!(status: "completed", completed_at: today)
        allow(Raven).to receive(:capture_exception) { @raven_called = true }
      end

      it "does not create a duplicate distributed_case" do
        subject.distribute!
        expect(subject.valid?).to eq(true)
        expect(subject.error?).to eq(false)
        expect(@raven_called).to eq(true)
      end
    end

    context "when the job errors" do
      it "marks the distribution as error" do
        allow_any_instance_of(LegacyDocket).to receive(:distribute_nonpriority_appeals).and_raise(StandardError)
        expect { subject.distribute! }.to raise_error(StandardError)
        expect(subject.status).to eq("error")
        expect(subject.distributed_cases.count).to eq(0)
        expect(subject.errored_at).to eq(Time.zone.now)
      end
    end

    context "when the judge has an empty team" do
      let(:judge_wo_attorneys) { create(:user) }
      let!(:vacols_judge_wo_attorneys) { create(:staff, :judge_role, sdomainid: judge_wo_attorneys.css_id) }

      subject { Distribution.create(judge: judge_wo_attorneys) }

      it "uses the alternative batch size" do
        subject.distribute!
        expect(subject.valid?).to eq(true)
        expect(subject.status).to eq("completed")
        expect(subject.statistics["batch_size"]).to eq(15)
        expect(subject.distributed_cases.count).to eq(15)
      end
    end

    context "when there are zero legacy cases eligible" do
      let!(:legacy_priority_cases) { [] }
      let!(:legacy_nonpriority_cases) { [] }
      let!(:same_judge_nonpriority_hearings) { [] }
      let!(:other_judge_hearings) { [] }

      it "fills the AMA dockets" do
        evidence_submission_cases[0...2].each do |appeal|
          appeal.tasks
            .find_by(type: EvidenceSubmissionWindowTask.name)
            .update!(status: :completed)
        end
        subject.distribute!
        expect(subject.valid?).to eq(true)
        expect(subject.status).to eq("completed")
        expect(subject.statistics["batch_size"]).to eq(15)
        expect(subject.statistics["total_batch_size"]).to eq(45)
        expect(subject.statistics["priority_count"]).to eq(1)
        expect(subject.statistics["legacy_proportion"]).to eq(0.0)
        expect(subject.statistics["direct_review_proportion"]).to be_within(0.01).of(0.13)
        expect(subject.statistics["evidence_submission_proportion"]).to be_within(0.01).of(0.43)
        expect(subject.statistics["hearing_proportion"]).to be_within(0.01).of(0.43)
        expect(subject.statistics["pacesetting_direct_review_proportion"]).to eq(0.1)
        expect(subject.statistics["interpolated_minimum_direct_review_proportion"]).to eq(0.067)
        expect(subject.statistics["nonpriority_iterations"]).to be_between(2, 3)
        expect(subject.distributed_cases.count).to eq(15)
      end
    end
  end

  context "validations" do
    subject { Distribution.create(judge: user) }

    let(:user) { judge }

    context "existing Distribution record with status pending" do
      let!(:existing_distribution) { create(:distribution, judge: judge) }

      it "prevents new Distribution record" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :pending_distribution)
      end
    end

    context "existing Distribution record with status started" do
      let!(:existing_distribution) { create(:distribution, judge: judge, status: :started) }

      it "prevents new Distribution record" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :pending_distribution)
      end
    end

    context "when the user is not a judge in VACOLS" do
      let(:user) { create(:user) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :not_judge)
      end
    end

    context "when the judge has 8 or fewer unassigned appeals" do
      before do
        5.times { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: Time.zone.today) }
        3.times { create(:ama_judge_task, assigned_to: judge, assigned_at: Time.zone.today) }
      end

      it "validates" do
        expect(subject.errors.details).not_to have_key(:judge)
      end
    end

    context "when the judge has 8 or more unassigned appeals" do
      before do
        5.times { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: Time.zone.today) }
        4.times { create(:ama_judge_task, assigned_to: judge, assigned_at: Time.zone.today) }
      end

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :too_many_unassigned_cases)
      end
    end

    context "when the judge has an appeal that has waited more than 30 days" do
      let!(:task) { create(:ama_judge_task, assigned_to: judge, assigned_at: 31.days.ago) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases_waiting_too_long)
      end
    end

    context "when the judge has a legacy appeal that has waited more than 30 days" do
      let!(:task) { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: 31.days.ago) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases_waiting_too_long)
      end
    end
  end
end
