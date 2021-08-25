# frozen_string_literal: true

describe Distribution, :all_dbs do
  let(:judge) { create(:user) }
  let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
  let(:member_count) { 5 }
  let(:attorneys) { create_list(:user, member_count) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:today) { Time.utc(2019, 1, 1, 12, 0, 0) }
  let(:original_distributed_case_id) { "#{case_id}-redistributed-#{today.strftime('%F')}" }
  let(:min_legacy_proportion) { DocketCoordinator::MINIMUM_LEGACY_PROPORTION }
  let(:max_direct_review_proportion) { DocketCoordinator::MAXIMUM_DIRECT_REVIEW_PROPORTION }

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
    before do
      allow_any_instance_of(DirectReviewDocket)
        .to receive(:nonpriority_receipts_per_year)
        .and_return(100)

      allow(Docket)
        .to receive(:nonpriority_decisions_per_year)
        .and_return(1000)
    end

    def create_legacy_case(index, traits = nil)
      create(
        :case,
        *traits,
        bfd19: 1.year.ago,
        bfac: "1",
        bfmpro: "ACT",
        bfcurloc: "81",
        bfdloout: index.days.ago,
        folder: build(
          :folder,
          tinum: "1801#{format('%<index>03d', index: index)}",
          titrnum: "123456789S"
        )
      )
    end

    def create_legacy_case_hearing_for(appeal, board_member: judge.vacols_attorney_id)
      create(:case_hearing,
             :disposition_held,
             folder_nr: appeal.bfkey,
             hearing_date: 1.month.ago,
             board_member: board_member)
    end

    context "priority_push is false" do
      before do
        allow_any_instance_of(HearingRequestDocket)
          .to receive(:age_of_n_oldest_genpop_priority_appeals)
          .and_return([])

        allow_any_instance_of(HearingRequestDocket)
          .to receive(:distribute_appeals)
          .and_return([])
      end

      subject { Distribution.create!(judge: judge) }

      let(:legacy_priority_count) { 14 }

      let!(:legacy_priority_cases) do
        (1..legacy_priority_count).map { |i| create_legacy_case(i, :aod) }
      end

      let!(:legacy_nonpriority_cases) do
        (15..100).map { |i| create_legacy_case(i) }
      end

      let!(:same_judge_priority_hearings) do
        legacy_priority_cases[0..1].map { |appeal| create_legacy_case_hearing_for(appeal) }
      end

      let!(:same_judge_nonpriority_hearings) do
        legacy_nonpriority_cases[29..33].map { |appeal| create_legacy_case_hearing_for(appeal) }
      end

      let!(:other_judge_hearings) do
        legacy_nonpriority_cases[2..27].map { |appeal| create_legacy_case_hearing_for(appeal, board_member: "1234") }
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

      context "when min legacy proportion and max direct review proportion are set and used" do
        # Proportion for hearings and evidence submission dockets
        let(:other_dockets_proportion) { (1 - min_legacy_proportion - max_direct_review_proportion) / 2 }

        it "correctly distributes cases" do
          evidence_submission_cases[0...2].each do |appeal|
            appeal.tasks
              .find_by(type: EvidenceSubmissionWindowTask.name)
              .update!(status: :completed)
          end

          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.priority_push).to eq(false)
          expect(subject.status).to eq("completed")
          expect(subject.started_at).to eq(Time.zone.now) # time is frozen so appears zero time elapsed
          expect(subject.errored_at).to be_nil
          expect(subject.completed_at).to eq(Time.zone.now)
          expect(subject.statistics["batch_size"]).to eq(15)
          expect(subject.statistics["total_batch_size"]).to eq(45)
          expect(subject.statistics["priority_count"]).to eq(legacy_priority_count + 1)
          expect(subject.statistics["legacy_proportion"]).to eq(min_legacy_proportion)
          expect(subject.statistics["legacy_hearing_backlog_count"]).to be <= 3
          expect(subject.statistics["direct_review_proportion"]).to eq(max_direct_review_proportion)
          expect(subject.statistics["evidence_submission_proportion"]).to be_within(0.01).of(other_dockets_proportion)
          expect(subject.statistics["hearing_proportion"]).to be_within(0.01).of(other_dockets_proportion)
          expect(subject.statistics["nonpriority_iterations"]).to be_between(1, 3)
          expect(subject.distributed_cases.count).to eq(15)
          expect(subject.distributed_cases.first.docket).to eq("legacy")
          expect(subject.distributed_cases.first.ready_at).to eq(2.days.ago.beginning_of_day)
          expect(subject.distributed_cases.where(priority: true).count).to eq(5)
          expect(subject.distributed_cases.where(genpop: true).count).to be_within(1).of(7)
          expect(subject.distributed_cases.where(priority: true, genpop: false).count).to eq(2)
          expect(subject.distributed_cases.where(priority: false, genpop_query: "not_genpop").count).to eq(0)
          expect(subject.distributed_cases.where(priority: false,
                                                 genpop_query: "any").map(&:docket_index).max).to eq(35)
          expect(subject.distributed_cases.where(priority: true,
                                                 docket: Constants.AMA_DOCKETS.direct_review).count).to eq(1)
          expect(subject.distributed_cases.where(docket: "legacy").count).to be >= 8
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.direct_review).count)
            .to be_within(1).of(1)
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.evidence_submission).count)
            .to be_within(1).of(0)
        end
      end

      context "with priority_acd on" do
        before { FeatureToggle.enable!(:priority_acd) }
        after { FeatureToggle.disable!(:priority_acd) }

        BACKLOG_LIMIT = VACOLS::CaseDocket::HEARING_BACKLOG_LIMIT

        let!(:more_same_judge_nonpriority_hearings) do
          to_add = total_tied_nonpriority_hearings - same_judge_nonpriority_hearings.count
          legacy_nonpriority_cases[34..(34 + to_add - 1)].map { |appeal| create_legacy_case_hearing_for(appeal) }
        end

        context "the judge's backlog has more than #{BACKLOG_LIMIT} legacy hearing non priority cases" do
          let(:total_tied_nonpriority_hearings) { BACKLOG_LIMIT + 5 }

          it "distributes legacy hearing non priority cases down to #{BACKLOG_LIMIT}" do
            expect(VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge))
              .to eq total_tied_nonpriority_hearings
            subject.distribute!
            expect(subject.valid?).to eq(true)
            # This may be less than BACKLOG_LIMIT when MINIMUM_LEGACY_PROPORTION is very large
            expect(subject.statistics["legacy_hearing_backlog_count"]).to be <= BACKLOG_LIMIT
            dcs_legacy = subject.distributed_cases.where(docket: "legacy")

            # distributions reliant on BACKLOG_LIMIT
            judge_tied_leg_distributions = total_tied_nonpriority_hearings - BACKLOG_LIMIT
            expect(dcs_legacy.where(priority: false, genpop_query: "not_genpop").count).to eq(
              judge_tied_leg_distributions
            )

            # distributions after handling BACKLOG_LIMIT
            expect(dcs_legacy.where(priority: true, genpop_query: "not_genpop").count).to eq(2)
            expect(dcs_legacy.where(priority: true, genpop_query: "any").count).to eq(2)
            expect(dcs_legacy.count).to be >= 8
          end
        end

        context "the judge's backlog has less than #{BACKLOG_LIMIT} legacy hearing non priority cases" do
          let(:total_tied_nonpriority_hearings) { BACKLOG_LIMIT - 5 }

          it "distributes legacy hearing non priority cases down to #{BACKLOG_LIMIT}" do
            expect(VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge))
              .to eq total_tied_nonpriority_hearings
            subject.distribute!

            expect(subject.valid?).to eq(true)
            dcs_legacy = subject.distributed_cases.where(docket: "legacy")

            # distributions reliant on BACKLOG_LIMIT
            expect(dcs_legacy.where(priority: false, genpop_query: "not_genpop").count).to eq(0)

            # distributions after handling BACKLOG_LIMIT
            remaining_in_backlog = total_tied_nonpriority_hearings -
                                   dcs_legacy.where(priority: false, genpop: false).count
            expect(subject.statistics["legacy_hearing_backlog_count"]).to eq remaining_in_backlog

            expect(dcs_legacy.where(priority: true, genpop_query: "not_genpop").count).to eq(2)
            expect(dcs_legacy.where(priority: true, genpop_query: "any").count).to eq(2)
            expect(dcs_legacy.count).to be >= 8
          end
        end
      end

      def create_nonpriority_distributed_case(distribution, case_id, ready_at)
        distribution.distributed_cases.create(
          case_id: case_id,
          priority: false,
          docket: "legacy",
          ready_at: VacolsHelper.normalize_vacols_datetime(ready_at),
          docket_index: "123",
          genpop: false,
          genpop_query: "any"
        )
      end

      def cancel_relevant_legacy_appeal_tasks
        legacy_appeal.tasks.reject { |t| t.type == "RootTask" }.each do |task|
          # update_columns to avoid triggers that will update VACOLS location dates and
          # mess up ACD date logic.
          task.update_columns(status: Constants.TASK_STATUSES.cancelled, closed_at: Time.zone.now)
        end
      end

      context "when a nonpriority distribution of an AMA appeal with an existing distributed case is attempted" do
        let(:judge_buggy) { create(:user) }
        let!(:judge_team_buggy) { JudgeTeam.create_for_judge(judge_buggy) }
        let!(:vacols_judge_buggy) { create(:staff, :judge_role, sdomainid: judge_buggy.css_id) }

        let!(:buggy_appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 :advanced_on_docket_due_to_age,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end

        let!(:past_distribution) { Distribution.create!(judge: judge_buggy) }

        let!(:past_distributed_case) do
          DistributedCase.create!(
            distribution: past_distribution,
            ready_at: 6.months.ago,
            docket: buggy_appeal.docket_type,
            priority: false,
            case_id: buggy_appeal.uuid,
            task: buggy_appeal.tasks.of_type("DistributionTask").first
          )
        end

        before do
          past_distribution.completed!
          first_distribution_task = buggy_appeal.tasks.find_by(type: "DistributionTask")
          first_distribution_task.completed!
        end

        subject { Distribution.create!(judge: judge) }

        it "allows other cases to be distributed" do
          subject.distribute!
        end
      end

      context "when an illegit nonpriority legacy case re-distribution is attempted" do
        let(:case_id) { legacy_case.bfkey }
        let!(:previous_location) { legacy_case.bfcurloc }
        let(:legacy_case) { legacy_nonpriority_cases.second }

        before do
          @raven_called = false
          distribution = create(:distribution, judge: judge)
          # illegit because appeal has open hearing tasks
          appeal = create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: legacy_case)
          appeal.tasks.open.where.not(type: RootTask.name).each(&:completed!)
          create_nonpriority_distributed_case(distribution, case_id, legacy_case.bfdloout)
          distribution.update!(status: "completed", completed_at: today)
          allow(Raven).to receive(:capture_exception) { @raven_called = true }
          allow_any_instance_of(RedistributedCase).to receive(:ok_to_redistribute?).and_return(false)
        end

        it "does not create a duplicate distributed_case and sends alert" do
          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.error?).to eq(false)
          expect(@raven_called).to eq(true)
          expect(subject.distributed_cases.pluck(:case_id)).to_not include(case_id)
          expect(legacy_case.reload.bfcurloc).to eq(previous_location)
        end
      end

      context "when a legit nonpriority legacy case re-distribution is attempted" do
        let(:case_id) { legacy_case.bfkey }
        let(:legacy_case) { legacy_nonpriority_cases.first }
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: legacy_case) }

        before do
          @raven_called = false
          distribution = create(:distribution, judge: judge)
          cancel_relevant_legacy_appeal_tasks
          create_nonpriority_distributed_case(distribution, case_id, legacy_case.bfdloout)
          distribution.update!(status: "completed", completed_at: today)
          allow(Raven).to receive(:capture_exception) { @raven_called = true }
        end

        it "renames existing case_id and does not create a duplicate distributed_case" do
          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.error?).to eq(false)
          expect(@raven_called).to eq(false)
          expect(subject.distributed_cases.pluck(:case_id)).to include(case_id)
          expect(DistributedCase.find_by(case_id: case_id)).to_not be_nil
          expect(DistributedCase.find_by(case_id: original_distributed_case_id)).to_not be_nil
          expect(legacy_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end

      def create_priority_distributed_case(distribution, case_id, ready_at)
        distribution.distributed_cases.create(
          case_id: case_id,
          priority: true,
          docket: "legacy",
          ready_at: VacolsHelper.normalize_vacols_datetime(ready_at),
          docket_index: "123",
          genpop: false,
          genpop_query: "any"
        )
      end

      context "when an illegit priority legacy case re-distribution is attempted" do
        let(:case_id) { legacy_case.bfkey }
        let(:legacy_case) { legacy_priority_cases.last }

        before do
          @raven_called = false
          distribution = create(:distribution, judge: judge)
          # illegit because appeal has open tasks
          create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: legacy_case)
          create_priority_distributed_case(distribution, case_id, legacy_case.bfdloout)
          distribution.update!(status: "completed", completed_at: today)
          allow(Raven).to receive(:capture_exception) { @raven_called = true }
        end

        it "does not create a duplicate distributed_case and sends alert" do
          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.error?).to eq(false)
          expect(@raven_called).to eq(false)
          expect(subject.distributed_cases.pluck(:case_id)).to_not include(case_id)
          expect(legacy_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:caseflow])
        end
      end

      context "when a legit priority legacy case re-distribution is attempted" do
        let(:case_id) { legacy_case.bfkey }
        let(:legacy_case) { legacy_priority_cases.last }
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: legacy_case) }

        before do
          @raven_called = false
          distribution = create(:distribution, judge: judge)
          cancel_relevant_legacy_appeal_tasks
          create_priority_distributed_case(distribution, case_id, legacy_case.bfdloout)
          distribution.update!(status: "completed", completed_at: today)
          allow(Raven).to receive(:capture_exception) { @raven_called = true }
        end

        it "renames existing case_id and does not create a duplicate distributed_case" do
          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.error?).to eq(false)
          expect(@raven_called).to eq(false)
          expect(subject.distributed_cases.pluck(:case_id)).to include(case_id)
          expect(DistributedCase.find_by(case_id: case_id)).to_not be_nil
          expect(DistributedCase.find_by(case_id: original_distributed_case_id)).to_not be_nil
          expect(legacy_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
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
        # Proportion for hearings and evidence submission dockets
        let(:other_dockets_proportion) { (1 - max_direct_review_proportion) / 2 }

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
          expect(subject.statistics["direct_review_proportion"]).to eq(max_direct_review_proportion)
          expect(subject.statistics["evidence_submission_proportion"]).to be_within(0.01).of(other_dockets_proportion)
          expect(subject.statistics["hearing_proportion"]).to be_within(0.01).of(other_dockets_proportion)
          expect(subject.statistics["nonpriority_iterations"]).to be_between(2, 3)
          expect(subject.distributed_cases.count).to eq(15)
        end
      end
    end

    context "priority_push is true" do
      subject { Distribution.create!(judge: judge, priority_push: true) }

      let!(:legacy_priority_cases) do
        (1..4).map do |i|
          create(
            :case,
            :aod,
            bfd19: 1.year.ago,
            bfac: "1",
            bfmpro: "ACT",
            bfcurloc: "81",
            bfdloout: i.months.ago,
            folder: build(
              :folder,
              tinum: "1801#{format('%<index>03d', index: i)}",
              titrnum: "123456789S"
            )
          )
        end
      end

      let!(:legacy_nonpriority_cases) do
        (5..8).map do |i|
          create(
            :case,
            bfd19: 1.year.ago,
            bfac: "1",
            bfmpro: "ACT",
            bfcurloc: "81",
            bfdloout: i.months.ago,
            folder: build(
              :folder,
              tinum: "1801#{format('%<index>03d', index: i)}",
              titrnum: "123456789S"
            )
          )
        end
      end

      let!(:priority_legacy_hearings_not_tied_to_judge) do
        legacy_priority_cases[0..1].map do |appeal|
          create(:case_hearing,
                 :disposition_held,
                 folder_nr: appeal.bfkey,
                 hearing_date: 1.month.ago)
        end
      end

      let!(:priority_legacy_hearings_tied_to_judge) do
        legacy_priority_cases[2..3].map do |appeal|
          create(:case_hearing,
                 :disposition_held,
                 folder_nr: appeal.bfkey,
                 hearing_date: 1.month.ago,
                 board_member: judge.vacols_attorney_id)
        end
      end

      let!(:priority_ama_hearings_tied_to_judge) do
        (1...5).map do
          appeal = create(:appeal,
                          :ready_for_distribution,
                          :advanced_on_docket_due_to_motion,
                          docket_type: Constants.AMA_DOCKETS.hearing)
          most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
          hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
          hearing.update(judge: judge)
          appeal
        end
      end

      let!(:priority_ama_hearings_not_tied_to_judge) do
        (1...3).map do |i|
          appeal = create(:appeal,
                          :advanced_on_docket_due_to_age,
                          :ready_for_distribution,
                          docket_type: Constants.AMA_DOCKETS.hearing)
          appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.months.ago)
          appeal.reload
        end
      end

      let!(:priority_direct_review_cases) do
        (1...3).map do |i|
          appeal = create(:appeal,
                          :with_post_intake_tasks,
                          :advanced_on_docket_due_to_age,
                          docket_type: Constants.AMA_DOCKETS.direct_review,
                          receipt_date: 1.month.ago)
          appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.month.ago)
          appeal
        end
      end

      let!(:evidence_submission_cases) do
        (1...3).map do |i|
          appeal = create(:appeal,
                          :with_post_intake_tasks,
                          :advanced_on_docket_due_to_age,
                          docket_type: Constants.AMA_DOCKETS.evidence_submission)
          appeal.tasks.find_by(type: EvidenceSubmissionWindowTask.name).completed!
          appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.month.ago)
          appeal
        end
      end

      context "when there is no limit specified" do
        it "distributes all priority cases associated with the judge" do
          distributed_case_ids = priority_legacy_hearings_tied_to_judge.map(&:folder_nr)
            .concat(priority_ama_hearings_tied_to_judge.map(&:uuid))
          subject.distribute!
          expect(subject.valid?).to eq(true)
          expect(subject.priority_push).to eq(true)
          expect(subject.status).to eq("completed")
          expect(subject.started_at).to eq(Time.zone.now) # time is frozen so appears zero time elapsed
          expect(subject.errored_at).to be_nil
          expect(subject.completed_at).to eq(Time.zone.now)
          expect(subject.statistics["batch_size"]).to eq(distributed_case_ids.count)
          expect(subject.distributed_cases.count).to eq(distributed_case_ids.count)
          expect(subject.distributed_cases.where(priority: true).count).to eq(distributed_case_ids.count)
          expect(subject.distributed_cases.where(priority: false).count).to eq(0)
          expect(subject.distributed_cases.where(genpop_query: "not_genpop").count).to eq(distributed_case_ids.count)
          expect(subject.distributed_cases.where(genpop: true).count).to eq(0)
          expect(subject.distributed_cases.where(docket: "legacy").count).to eq(
            priority_legacy_hearings_tied_to_judge.count
          )
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.hearing).count).to eq(
            priority_ama_hearings_tied_to_judge.count
          )
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.direct_review).count).to eq 0
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.evidence_submission).count).to eq 0
          expect(subject.distributed_cases.pluck(:case_id)).to match_array distributed_case_ids
        end
      end

      context "when a limit is specified" do
        let(:limit) { 4 }

        it "distributes that number of priority cases from all dockets, based on docket age" do
          oldest_case_from_each_docket = [
            legacy_priority_cases.last.bfkey,
            priority_ama_hearings_not_tied_to_judge.last.uuid,
            priority_direct_review_cases.last.uuid,
            evidence_submission_cases.last.uuid
          ]

          subject.distribute!(limit)
          expect(subject.valid?).to eq(true)
          expect(subject.priority_push).to eq(true)
          expect(subject.status).to eq("completed")
          expect(subject.started_at).to eq(Time.zone.now) # time is frozen so appears zero time elapsed
          expect(subject.errored_at).to be_nil
          expect(subject.completed_at).to eq(Time.zone.now)
          expect(subject.statistics["batch_size"]).to eq(limit)
          expect(subject.distributed_cases.count).to eq(limit)
          expect(subject.distributed_cases.where(priority: true).count).to eq(limit)
          expect(subject.distributed_cases.where(priority: false).count).to eq(0)
          expect(subject.distributed_cases.where(genpop_query: "not_genpop").count).to eq(0)
          expect(subject.distributed_cases.where(docket: "legacy").count).to eq(1)
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.hearing).count).to eq(1)
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.direct_review).count).to eq(1)
          expect(subject.distributed_cases.where(docket: Constants.AMA_DOCKETS.evidence_submission).count).to eq(1)
          expect(subject.distributed_cases.pluck(:case_id)).to match_array oldest_case_from_each_docket
        end
      end
    end
  end

  context "validations" do
    shared_examples "passes validations" do
      it "is valid" do
        expect(subject.valid?).to be true
      end
    end

    subject { Distribution.create(judge: user, priority_push: priority_push) }

    let(:user) { judge }
    let(:priority_push) { false }

    context "existing Distribution record with status pending" do
      let!(:existing_distribution) { create(:distribution, judge: judge) }

      it "prevents new Distribution record" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :pending_distribution)
      end

      context "when the priority_push is not the same" do
        let!(:existing_distribution) { create(:distribution, judge: judge, priority_push: true) }

        it_behaves_like "passes validations"
      end
    end

    context "existing Distribution record with status started" do
      let!(:existing_distribution) { create(:distribution, judge: judge, status: :started) }

      it "prevents new Distribution record" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :pending_distribution)
      end

      context "when the priority_push is not the same" do
        let!(:existing_distribution) { create(:distribution, judge: judge, status: :started, priority_push: true) }

        it_behaves_like "passes validations"
      end
    end

    context "when the user is not a judge in VACOLS" do
      let(:user) { create(:user) }

      it "is invalid" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :not_judge)
      end
    end

    context "when the judge has 8 or fewer unassigned appeals" do
      before do
        5.times { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: Time.zone.today) }
        3.times { create(:ama_judge_assign_task, assigned_to: judge, assigned_at: Time.zone.today) }
      end

      it "is valid" do
        expect(subject.errors.details).not_to have_key(:judge)
      end
    end

    context "when the judge has 8 or more unassigned appeals" do
      before do
        5.times { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: Time.zone.today) }
        4.times { create(:ama_judge_assign_task, assigned_to: judge, assigned_at: Time.zone.today) }
      end

      it "is invalid" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :too_many_unassigned_cases)
      end

      context "when priority_push is true" do
        let(:priority_push) { true }

        it_behaves_like "passes validations"
      end
    end

    context "when the judge has an appeal that has waited more than 30 days" do
      let!(:task) { create(:ama_judge_assign_task, assigned_to: judge, assigned_at: 31.days.ago) }

      it "is invalid" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases_waiting_too_long)
      end

      context "when priority_push is true" do
        let(:priority_push) { true }

        it_behaves_like "passes validations"
      end
    end

    context "when the judge has a legacy appeal that has waited more than 30 days" do
      let!(:task) { create(:case, bfcurloc: vacols_judge.slogid, bfdloout: 31.days.ago) }

      it "is invalid" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases_waiting_too_long)
      end

      context "when priority_push is true" do
        let(:priority_push) { true }

        it_behaves_like "passes validations"
      end
    end
  end
end
