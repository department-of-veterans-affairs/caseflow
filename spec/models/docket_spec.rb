# frozen_string_literal: true

require_relative "../../app/models/tasks/mail_task"

describe Docket, :all_dbs do
  before do
    create(:case_distribution_lever, :ama_direct_review_docket_time_goals)
    create(:case_distribution_lever, :ama_evidence_submission_docket_time_goals)
    create(:case_distribution_lever, :ama_hearing_docket_time_goals)
    create(:case_distribution_lever, :ama_hearing_start_distribution_prior_to_goals)
    create(:case_distribution_lever, :ama_hearing_case_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_aod_affinity_days)
    create(:case_distribution_lever, :ama_direct_review_start_distribution_prior_to_goals)
    create(:case_distribution_lever, :ama_evidence_submission_review_start_distribution_prior_to_goals)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :aoj_cavc_affinity_days)
    create(:case_distribution_lever, :aoj_aod_affinity_days)
    create(:case_distribution_lever, :aoj_affinity_days)
    create(:case_distribution_lever, :request_more_cases_minimum)
    create(:case_distribution_lever, :disable_ama_non_priority_direct_review)
  end

  context "docket" do
    # nonpriority
    let!(:appeal) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let!(:denied_aod_motion_appeal) do
      create(:appeal,
             :denied_advance_on_docket,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let!(:inapplicable_aod_motion_appeal) do
      create(:appeal,
             :inapplicable_aod_motion,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let!(:evidence_docket_appeal) do
      create(:appeal,
             :evidence_submission_docket,
             :with_post_intake_tasks)
    end

    # priority
    let!(:aod_age_appeal) do
      create(:appeal,
             :advanced_on_docket_due_to_age,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let!(:aod_motion_appeal) do
      create(:appeal,
             :advanced_on_docket_due_to_motion,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end

    let!(:hearing_appeal) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.hearing)
    end
    let!(:evidence_submission_appeal) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.evidence_submission)
    end
    let!(:cavc_appeal) do
      create(:appeal,
             :type_cavc_remand,
             :cavc_ready_for_distribution,
             :with_appeal_affinity,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             affinity_start_date: affinity_start_date)
    end
    let(:affinity_start_date) { Time.zone.now }

    context "docket type" do
      # docket_type is implemented in the subclasses and should error if called here
      context "when docket type is called directly" do
        subject { Docket.new.docket_type }
        it "throws an error" do
          expect { subject }.to raise_error(Caseflow::Error::MustImplementInSubclass)
        end
      end
    end

    describe "affinity_date_count" do
      context "when case distribution lever value is infinite" do
        subject { DirectReviewDocket.new.affinity_date_count(true, true) }
        before do
          CaseDistributionLever.find_by(item: "cavc_affinity_days").update(value: "infinite")
        end

        it "Does not raise an error and return results" do
          expect(subject).to eq(1)
        end
      end
    end

    context "appeals" do
      context "when no options given" do
        subject { DirectReviewDocket.new.appeals }
        it "returns all appeals if no option given" do
          expect(subject).to include appeal
          expect(subject).to include denied_aod_motion_appeal
          expect(subject).to include inapplicable_aod_motion_appeal
          expect(subject).to include aod_age_appeal
          expect(subject).to include aod_motion_appeal
          expect(subject).to include cavc_appeal
        end
      end

      context "when there is a judge and the distribution is not_genpop" do
        let(:other_judge) { create(:user, :judge, :with_judge_team) }

        let(:cavc_remand) { cavc_appeal.cavc_remand }
        let(:source_appeal) { cavc_remand.source_appeal }
        let(:judge_decision_review_task) do
          source_appeal.tasks.where(
            type: "JudgeDecisionReviewTask",
            status: "completed"
          ).first
        end

        context "when called for another judge who has no affinity" do
          subject { DirectReviewDocket.new.appeals(ready: true, genpop: "not_genpop", judge: other_judge) }

          it "returns no appeals" do
            expect(subject.to_a.length).to eq 0
          end
        end

        context "when called for the judge with affinity" do
          let(:judge) { judge_decision_review_task.assigned_to }
          subject { DirectReviewDocket.new.appeals(ready: true, genpop: "not_genpop", judge: judge) }

          it "returns only the cavc appeal" do
            expect(subject).to match_array([cavc_appeal])
          end
        end

        context "when acd_exclude_from_affinity flag is enabled" do
          before { FeatureToggle.enable!(:acd_exclude_from_affinity) }
          after { FeatureToggle.disable!(:acd_exclude_from_affinity) }

          context "when called for ready is true and judge is passed" do
            let(:judge) { judge_decision_review_task.assigned_to }

            subject { DirectReviewDocket.new.appeals(ready: true, priority: false, judge: judge) }

            it "returns non priority appeals" do
              expect(subject).to match_array([appeal, denied_aod_motion_appeal, inapplicable_aod_motion_appeal])
            end
          end
        end
      end

      context "when ready is false" do
        subject { DirectReviewDocket.new.appeals(priority: true, ready: false) }
        it "throws an error" do
          expect { subject }.to raise_error(
            StandardError, "'ready for distribution' value cannot be false"
          )
        end
      end

      context "when looking for only priority and ready appeals" do
        subject { DirectReviewDocket.new.appeals(priority: true, ready: true) }
        it "returns priority/ready appeals" do
          expect(subject).to_not include appeal
          expect(subject).to_not include denied_aod_motion_appeal
          expect(subject).to_not include inapplicable_aod_motion_appeal
          expect(subject).to include aod_age_appeal
          expect(subject).to include aod_motion_appeal
          expect(subject).to include cavc_appeal
        end

        context "when aod appeal with claimants person does not contain DOB" do
          let!(:other_aod_age_appeal) do
            create(:appeal,
                   :advanced_on_docket_due_to_age,
                   :with_post_intake_tasks,
                   docket_type: Constants.AMA_DOCKETS.direct_review,
                   aod_based_on_age: false)
          end

          before do
            aod_age_appeal.claimants.first.person.update!(date_of_birth: nil)
            other_aod_age_appeal.claimants.first.person.update!(date_of_birth: nil)
          end

          it "returns aod appeal in priority/ready appeals" do
            expect(subject).to include aod_age_appeal
            expect(subject).to_not include inapplicable_aod_motion_appeal
          end
        end
      end

      context "when looking for only nonpriority appeals" do
        subject { DirectReviewDocket.new.appeals(priority: false) }
        it "returns nonpriority appeals" do
          expect(subject).to include appeal
          expect(subject).to include denied_aod_motion_appeal
          expect(subject).to include inapplicable_aod_motion_appeal
          expect(subject).to_not include aod_age_appeal
          expect(subject).to_not include aod_motion_appeal
          expect(subject).to_not include cavc_appeal
        end

        context "when aod appeal with claimants person does not contain DOB" do
          let!(:other_aod_age_appeal) do
            create(:appeal,
                   :advanced_on_docket_due_to_age,
                   :with_post_intake_tasks,
                   docket_type: Constants.AMA_DOCKETS.direct_review,
                   aod_based_on_age: false)
          end

          before do
            aod_age_appeal.claimants.first.person.update!(date_of_birth: nil)
            other_aod_age_appeal.claimants.first.person.update!(date_of_birth: nil)
          end

          it "returns aod nonpriority appeals" do
            expect(subject).not_to include aod_age_appeal
            expect(subject).to include inapplicable_aod_motion_appeal
          end
        end
      end

      context "when only looking for appeals that are ready for distribution" do
        subject { DirectReviewDocket.new.appeals(ready: true) }

        it "only returns active appeals that meet both of these conditions:
            it has at least one Distribution Task with status assigned
            AND
            it doesn't have any blocking Mail Tasks." do
          expected_appeals = [
            appeal,
            denied_aod_motion_appeal,
            inapplicable_aod_motion_appeal,
            aod_age_appeal,
            aod_motion_appeal,
            cavc_appeal
          ]
          expect(subject).to match_array(expected_appeals)
        end
      end

      context "when looking for priority appeals" do
        it "returns appeals with distribution tasks ordered by when they became ready for distribution" do
          aod_age_appeal.tasks.find { |task| task.is_a?(DistributionTask) }.update!(assigned_at: 2.days.ago)
          aod_motion_appeal.tasks.find { |task| task.is_a?(DistributionTask) }.update!(assigned_at: 5.days.ago)

          sorted_appeals = DirectReviewDocket.new.appeals(priority: true, ready: true)

          expect(sorted_appeals[0]).to eq aod_motion_appeal
        end
      end

      context "appeal has mail tasks" do
        subject { DirectReviewDocket.new.appeals(ready: true) }

        let(:user) { create(:user) }

        before do
          MailTeam.singleton.add_user(user)
        end

        context "nonblocking mail tasks" do
          it "includes those appeals" do
            nonblocking_appeal = create(:appeal,
                                        :with_post_intake_tasks,
                                        docket_type: Constants.AMA_DOCKETS.direct_review)
            AodMotionMailTask.create_from_params({
                                                   appeal: nonblocking_appeal,
                                                   parent_id: nonblocking_appeal.root_task.id
                                                 }, user)

            expect(subject).to include nonblocking_appeal
          end
        end

        context "blocking mail tasks with status not completed or cancelled" do
          it "excludes those appeals" do
            blocking_appeal = create(:appeal,
                                     :with_post_intake_tasks,
                                     docket_type: Constants.AMA_DOCKETS.direct_review)
            CongressionalInterestMailTask.create_from_params({
                                                               appeal: blocking_appeal,
                                                               parent_id: blocking_appeal.root_task.id
                                                             }, user)

            expect(subject).to_not include blocking_appeal
          end
        end

        context "blocking mail tasks with status completed or cancelled" do
          it "includes those appeals" do
            with_blocking_but_closed_tasks = create(:appeal,
                                                    :with_post_intake_tasks,
                                                    docket_type: Constants.AMA_DOCKETS.direct_review)
            FoiaRequestMailTask.create_from_params({
                                                     appeal: with_blocking_but_closed_tasks,
                                                     parent_id: with_blocking_but_closed_tasks.root_task.id
                                                   }, user)
            FoiaRequestMailTask.find_by(appeal: with_blocking_but_closed_tasks).update!(status: "completed")

            expect(subject).to include with_blocking_but_closed_tasks
          end
        end
      end
    end

    context "count" do
      let(:priority) { nil }
      let(:ready) { nil }
      subject { DirectReviewDocket.new.count(priority: priority, ready: ready) }

      it "counts all active appeals on the docket" do
        expect(subject).to eq(6)
      end

      context "when looking for ready appeals" do
        let(:ready) { true }
        it "counts only ready appeals" do
          expect(subject).to eq(6)
        end
      end

      context "when looking for nonpriority appeals" do
        let(:priority) { false }
        it "counts active nonpriority appeals" do
          expect(subject).to eq(3)
        end
      end

      context "when looking for priority appeals" do
        let(:priority) { true }
        it "counts active priority appeals" do
          expect(subject).to eq(3)
        end
      end
    end

    context "genpop priority count" do
      let(:docket) { DirectReviewDocket.new }
      subject { docket.genpop_priority_count }

      it "counts genpop priority appeals" do
        expect(subject).to eq(3)
      end

      context "when acd_exclude_from_affinity flag is enabled" do
        before { FeatureToggle.enable!(:acd_exclude_from_affinity) }
        after { FeatureToggle.disable!(:acd_exclude_from_affinity) }
        let(:docket) { HearingRequestDocket.new }
        let!(:cavc_appeal2) do
          create(:appeal,
                 :type_cavc_remand,
                 :cavc_ready_for_distribution,
                 :with_appeal_affinity,
                 docket_type: Constants.AMA_DOCKETS.hearing,
                 affinity_start_date: 2.days.ago)
        end
        let!(:cavc_appeal3) do
          create(:appeal,
                 :type_cavc_remand,
                 :cavc_ready_for_distribution,
                 :with_appeal_affinity,
                 docket_type: Constants.AMA_DOCKETS.hearing,
                 affinity_start_date: 80.days.ago)
        end
        subject { docket.genpop_priority_count }

        it "correctly filters out appeals within affinity window" do
          expect(subject).to eq(1)
        end
      end
    end

    context "ready_priority_nonpriority_appeals" do
      let(:docket) { DirectReviewDocket.new }
      let(:judge) { create(:user, :judge, :with_judge_team) }

      it "returns appeals when the corresponding CaseDistributionLever value is false" do
        CaseDistributionLever.where(item: "disable_ama_non_priority_direct_review").update(value: false)
        result = docket.ready_priority_nonpriority_appeals(priority: false)
        expected_appeals = docket.appeals(priority: false, ready: true)
        expect(result.map(&:id)).to eq(expected_appeals.map(&:id))
      end

      it "returns docket when the corresponding CaseDistributionLever value is false" do
        CaseDistributionLever.where(item: "disable_ama_non_priority_direct_review").update(value: false)
        result = docket.ready_priority_nonpriority_appeals(priority: false, ready: true, genpop: true, judge: judge)
        expected_attributes = docket.appeals(
          priority: false,
          ready: true,
          genpop: true,
          judge: judge
        ).map(&:attributes)
        result_attributes = result.map(&:attributes)
        expect(result_attributes).to eq(expected_attributes)
      end

      it "returns an empty array when the corresponding CaseDistributionLever value is true" do
        lever = CaseDistributionLever.find_by(item: "disable_ama_non_priority_direct_review")
        lever.update(value: "true")
        expect(lever.value).to eq("true")
        result = docket.ready_priority_nonpriority_appeals(priority: false)
        expect(result).to eq([])
      end

      it "returns an empty list when the corresponding CaseDistributionLever record is not found" do
        result = docket.ready_priority_nonpriority_appeals(priority: false)
        expected_result = docket.appeals(priority: false, ready: true)
        expect(result.map(&:id)).to eq(expected_result.map(&:id))
      end

      it "returns an empty array when the lever value is true and priority is true" do
        allow(CaseDistributionLever).to receive(:find_by_item).and_return(double(value: "true"))
        expect(docket.ready_priority_nonpriority_appeals(ready: true)).to eq([])
      end

      it "returns the correct appeals when the lever value is false and priority is true" do
        expected_appeals = docket.appeals(priority: true)
        result = docket.ready_priority_nonpriority_appeals(priority: true, ready: true)
        expect(result).to match_array(expected_appeals)
      end

      context "when start_distribution_prior_to_goal toggle is off" do
        before do
          CaseDistributionLever.find_by(item: "ama_direct_review_start_distribution_prior_to_goals")
            .update!(is_toggle_active: false)
        end

        it "returns the correct appeals" do
          expected_appeals = docket.appeals(priority: true)
          result = docket.ready_priority_nonpriority_appeals(priority: true, ready: true)
          expect(result).to match_array(expected_appeals)
        end
      end

      context "when start_distribution_prior_to_goal toggle is on" do
        before do
          CaseDistributionLever.find_by(item: "ama_direct_review_start_distribution_prior_to_goals")
            .update!(is_toggle_active: true, value: 345)
        end

        context "with non-priority appeals" do
          before do
            [appeal, denied_aod_motion_appeal, inapplicable_aod_motion_appeal].each do |np_appeal|
              np_appeal.update!(receipt_date: 22.days.ago)
            end
          end

          it "returns the appeals with in docket time goal days" do
            result = docket.ready_priority_nonpriority_appeals(priority: false, ready: true)
            expected_appeals = docket.appeals(priority: false, ready: true)
            expect(result).to match_array(expected_appeals)
          end
        end

        context "with priority appeals" do
          it "returns the appeals without docket time goal days" do
            result = docket.ready_priority_nonpriority_appeals(priority: true, ready: true)
            expected_appeals = docket.appeals(priority: true, ready: true)
            expect(result).to match_array(expected_appeals)
          end
        end
      end
    end

    context "lever item construction" do
      let(:docket) { DirectReviewDocket.new }

      it "correctly builds the lever item based on docket type" do
        allow(docket).to receive(:docket_type).and_return("direct_review")

        lever_item_key = "disable_ama_non_priority_direct_review"
        allow(CaseDistributionLever).to receive(:find_by).and_call_original
        allow(CaseDistributionLever).to receive(:find_by).with(item: lever_item_key).and_return(double(value: "false"))

        expect(docket).to receive(:ready_priority_nonpriority_appeals).and_call_original

        docket.ready_priority_nonpriority_appeals(priority: false)
      end
    end

    context "age_of_n_oldest_genpop_priority_appeals" do
      subject { DirectReviewDocket.new.age_of_n_oldest_genpop_priority_appeals(1) }

      it "returns the 'ready at' field of the oldest priority appeals that are ready for distribution" do
        expect(subject.length).to eq(1)
        expect(subject.first).to eq(aod_age_appeal.ready_for_distribution_at)
      end
    end

    context "age_of_n_oldest_priority_appeals_available_to_judge" do
      # Set cavc_appeal to be outside its affinity window
      let(:affinity_start_date) { (CaseDistributionLever.cavc_affinity_days + 7).days.ago }
      let(:judge) { create(:user, :with_vacols_judge_record) }
      let!(:cavc_appeal_no_appeal_affinity) do
        create_ready_cavc_appeal_without_appeal_affinity(tied_judge: judge, created_date: 7.days.ago)
      end

      before do
        FeatureToggle.enable!(:acd_exclude_from_affinity)
        FeatureToggle.enable!(:acd_distribute_by_docket_date)
      end

      subject { DirectReviewDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(judge, 5) }

      it "returns the receipt_date field of the oldest direct review priority appeals ready for distribution" do
        expect(subject.length).to eq(4)
        expect(subject).to match_array([aod_age_appeal.receipt_date,
                                        aod_motion_appeal.receipt_date,
                                        cavc_appeal.receipt_date,
                                        cavc_appeal_no_appeal_affinity.receipt_date])
      end
    end

    context "age_of_n_oldest_nonpriority_appeals_available_to_judge" do
      let(:judge) { create(:user, :with_vacols_judge_record) }
      let(:expected_result) do
        [appeal.receipt_date, denied_aod_motion_appeal.receipt_date, inapplicable_aod_motion_appeal.receipt_date]
      end

      before do
        FeatureToggle.enable!(:acd_exclude_from_affinity)
        FeatureToggle.enable!(:acd_distribute_by_docket_date)
      end

      before do
        FeatureToggle.enable!(:acd_exclude_from_affinity)
        FeatureToggle.enable!(:acd_distribute_by_docket_date)
      end

      subject { DirectReviewDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, 5) }

      it "returns the receipt_date field of the oldest direct review priority appeals ready for distribution" do
        expect(subject.length).to eq(3)
        expect(subject).to eq(expected_result)
      end

      context "when calculated time goal days are 20" do
        before do
          CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_direct_review_docket_time_goals)
            .update!(value: 385)
          appeal.update!(receipt_date: 25.days.ago)
          denied_aod_motion_appeal.update!(receipt_date: 25.days.ago)
        end

        it "returns only receipt_date with in the time goal" do
          expect(subject.length).to eq(2)
          expect(subject).to eq([appeal.receipt_date, denied_aod_motion_appeal.receipt_date])
        end
      end

      context "when start_distribution_prior_to_goal toggle off" do
        before do
          CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals)
            .update!(is_toggle_active: false)
        end

        it "returns only receipt_date with in the time goal" do
          expect(subject.length).to eq(3)
          expect(subject).to eq(expected_result)
        end
      end
    end

    context "age_of_oldest_priority_appeal" do
      let(:docket) { DirectReviewDocket.new }

      subject { docket.age_of_oldest_priority_appeal }

      it "returns the 'ready at' field of the oldest priority appeal that is ready for distribution" do
        expect(subject).to eq(aod_age_appeal.ready_for_distribution_at)
      end

      context "when there are no ready priority appeals" do
        let(:docket) { EvidenceSubmissionDocket.new }

        it "returns nil" do
          expect(subject.nil?).to be true
        end
      end
    end

    context "days waiting for age_of_oldest_priority_appeal" do
      let!(:old_priority_direct_review_case) do
        appeal = create(:appeal,
                        :with_post_intake_tasks,
                        :advanced_on_docket_due_to_age,
                        docket_type: Constants.AMA_DOCKETS.direct_review,
                        receipt_date: 1.month.ago)
        appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: 1.week.ago)
      end
      let(:docket) { DirectReviewDocket.new }

      subject { docket.oldest_priority_appeal_days_waiting }

      it "returns today's date less the age" do
        expect(subject).to eq(7)
      end
    end

    context "ready priority appeal ids" do
      let(:docket) { DirectReviewDocket.new }

      subject { docket.ready_priority_appeal_ids }
      it "returns the uuids of the ready priority appeals" do
        expect(subject).to_not include appeal.uuid
        expect(subject).to_not include denied_aod_motion_appeal.uuid
        expect(subject).to_not include inapplicable_aod_motion_appeal.uuid
        expect(subject).to include aod_age_appeal.uuid
        expect(subject).to include aod_motion_appeal.uuid
        expect(subject).to include cavc_appeal.uuid
      end
    end

    context "distribute_appeals for CAVC" do
      let(:cavc_distribution_task) { cavc_appeal.tasks.where(type: DistributionTask.name).first }
      let(:cavc_remand) { cavc_appeal.cavc_remand }
      let(:source_appeal) { cavc_remand.source_appeal }
      let(:judge_decision_review_task) do
        source_appeal.tasks.where(
          type: "JudgeDecisionReviewTask",
          status: "completed"
        ).first
      end

      context "when the cavc remand is within affinity (< 21 days)" do
        let(:first_judge) { create(:user, :judge, :with_vacols_judge_record) }
        let(:first_distribution) { Distribution.create!(judge: first_judge) }

        let(:second_judge) { judge_decision_review_task.assigned_to }
        let(:second_distribution) { Distribution.create!(judge: second_judge) }

        before do
          cavc_distribution_task.update!(assigned_at: Time.zone.now)
        end

        it "is distributed only to the issuing judge" do
          # priority: true would normally return CAVC tasks, so if not for affinity, this should include it:
          dist_cases = DirectReviewDocket.new.distribute_appeals(
            first_distribution,
            genpop: "not_genpop",
            priority: true,
            limit: 3
          )
          expect(dist_cases.map(&:case_id)).not_to include(cavc_appeal.uuid)

          # But because of affinity, it sticks to this judge user:
          dist_cases = DirectReviewDocket.new.distribute_appeals(
            second_distribution,
            genpop: "not_genpop",
            priority: true,
            limit: 3
          )
          expect(dist_cases.map(&:case_id)).to include(cavc_appeal.uuid)
        end
      end

      context "when the cavc remand is outside of affinity (>= 21 days)" do
        let(:first_judge) { judge_decision_review_task.assigned_to }
        let(:first_distribution) { Distribution.create!(judge: first_judge) }

        let(:second_judge) { create(:user, :judge, :with_vacols_judge_record) }
        let(:second_distribution) { Distribution.create!(judge: second_judge) }

        let(:affinity_start_date) { (CaseDistributionLever.cavc_affinity_days + 1).days.ago }

        context "when genpop: not_genpop is set" do
          it "is not distributed because it is now genpop" do
            dist_cases = DirectReviewDocket.new.distribute_appeals(
              first_distribution,
              genpop: "not_genpop",
              priority: true,
              limit: 3
            )

            expect(dist_cases.map(&:case_id)).not_to include(cavc_appeal.uuid)
          end
        end

        context "when genpop is not 'not_genpop' (i.e., is genpop)" do
          it "is distributed to the first available judge" do
            dist_cases = DirectReviewDocket.new.distribute_appeals(
              second_distribution,
              genpop: "any",
              priority: true,
              limit: 3
            )

            expect(dist_cases.map(&:case_id)).to include(cavc_appeal.uuid)
          end
        end
      end

      context "priority appeals" do
        subject { DirectReviewDocket.new.distribute_appeals(distribution, priority: true, limit: 3) }

        let(:judge_user) { create(:user) }
        let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
        let!(:distribution) { Distribution.create!(judge: judge_user) }

        it "distributes the priority appeals" do
          distributed_cases = subject
          # cavc_appeal is priority, but out of affinity and thus not included:
          expected_appeal_ids = [aod_age_appeal.uuid, aod_motion_appeal.uuid]
          expect(distributed_cases.map(&:case_id)).to match_array(expected_appeal_ids)
          expect(distributed_cases.first.class).to eq(DistributedCase)
          expect(distribution.distributed_cases.map(&:case_id)).to eq(expected_appeal_ids)
          judge_appeals = judge_user.reload.tasks.map(&:appeal)
          expect(judge_appeals).to include(aod_age_appeal)
          expect(judge_appeals).to include(aod_motion_appeal)
        end
      end
    end

    describe ".nonpriority_decisions_per_year" do
      let!(:newer_non_priority_decisions) do
        2.times do
          doc = create(:decision_document, decision_date: 20.days.ago)
          doc.appeal.update(docket_type: Constants.AMA_DOCKETS.direct_review)
          doc.appeal
        end
      end
      let!(:older_non_priority_decision) do
        doc = create(:decision_document, decision_date: 380.days.ago)
        doc.appeal.update(docket_type: Constants.AMA_DOCKETS.direct_review)
        doc.appeal
      end
      let!(:newer_priority_decision) do
        appeal = create(:appeal,
                        :advanced_on_docket_due_to_age,
                        :with_post_intake_tasks,
                        docket_type: Constants.AMA_DOCKETS.direct_review)
        create(:decision_document, decision_date: 20.days.ago, appeal: appeal)
        appeal
      end
      let!(:older_priority_decision) do
        appeal = create(:appeal,
                        :advanced_on_docket_due_to_age,
                        :with_post_intake_tasks,
                        docket_type: Constants.AMA_DOCKETS.direct_review)
        create(:decision_document, decision_date: 380.days.ago, appeal: appeal)
        appeal
      end

      context "non-priority decision list" do
        subject { Docket.nonpriority_decisions_per_year }

        it "returns nonpriority decisions from the last year" do
          expect(subject).to eq(3)
        end
      end
    end
  end

  context "an appeal has already been distributed" do
    subject { DirectReviewDocket.new.distribute_appeals(current_distribution, limit: 3) }
    let!(:judge_user) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_2") }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let!(:past_distribution) { Distribution.create!(judge: judge_user) }
    let(:current_distribution) do
      past_distribution.completed!
      Distribution.create!(judge: judge_user)
    end

    let!(:distributed_appeal) do
      create(:appeal,
             :assigned_to_judge,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             associated_judge: judge_user)
    end
    let!(:distributed_case) do
      DistributedCase.create!(
        distribution: past_distribution,
        ready_at: 6.months.ago,
        docket: distributed_appeal.docket_type,
        priority: false,
        case_id: distributed_appeal.uuid,
        task: distributed_appeal.tasks.of_type("DistributionTask").first,
        sct_appeal: false
      )
    end
    let!(:second_distribution_task) do
      create(:distribution_task, appeal: distributed_appeal, status: Constants.TASK_STATUSES.assigned)
    end
    let!(:appeal_second) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             associated_judge: judge_user)
    end
    let!(:appeal_third) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             associated_judge: judge_user)
    end

    before do
      judge_assign_task = JudgeAssignTask.find_by(appeal_id: distributed_appeal.id)
      judge_assign_task.cancelled!
      second_distribution_task.assigned!
    end

    it "distributes appeals including the one that has been distributed" do
      expect(current_distribution.distributed_cases.length).to eq(0)
      result = subject

      expect(current_distribution.distributed_cases.length).to eq(3)
      expect(result[0].class).to eq(DistributedCase)
      expect(result[1].class).to eq(DistributedCase)
      expect(result[2].class).to eq(DistributedCase)
    end

    it "sets the case ids when a redistribution occurs" do
      ymd = Time.zone.today.strftime("%F")
      result = subject

      expect(DistributedCase.find(distributed_case.id).case_id).to eq("#{distributed_appeal.uuid}-redistributed-#{ymd}")
      expect(result.any? { |item| item.case_id == distributed_appeal.uuid }).to be_truthy
    end
  end

  context "distribute_appeals" do
    let!(:appeals) do
      (1..10).map do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
    end

    let(:judge_user) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let!(:distribution) { Distribution.create!(judge: judge_user) }
    let!(:sct_org) { SpecialtyCaseTeam.singleton }

    context "nonpriority appeals" do
      subject { DirectReviewDocket.new.distribute_appeals(distribution, priority: false, limit: 10) }

      it "creates distributed cases and judge tasks" do
        tasks = subject

        expect(tasks.length).to eq(10)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(distribution.distributed_cases.length).to eq(10)
        expect(judge_user.reload.tasks.map(&:appeal)).to include(appeals.first)
      end
    end
  end

  context "distribute_appeals to Specialty Case Team" do
    let!(:appeals) do
      [
        (1..num_appeals_before).map do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: docket_type,
                 receipt_date: 5.days.ago)
        end,
        (1..num_vha_appeals).map do
          create(:appeal, :with_post_intake_tasks, :with_vha_issue, docket_type: docket_type, receipt_date: 3.days.ago)
        end,
        (1..num_appeals_after).map do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: docket_type,
                 receipt_date: 2.days.ago)
        end
      ].flatten
    end

    let(:judge_user) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let!(:distribution) { Distribution.create!(judge: judge_user) }
    let!(:sct_org) { SpecialtyCaseTeam.singleton }
    let(:num_vha_appeals) { 5 }
    let(:num_appeals_before) { 3 }
    let(:num_appeals_after) { 10 }
    let(:docket_type) { Constants.AMA_DOCKETS.direct_review }
    let(:limit) { 5 }

    context "with the SCT feature toggle enabled" do
      before do
        FeatureToggle.enable!(:specialty_case_team_distribution)
      end

      after do
        FeatureToggle.disable!(:specialty_case_team_distribution)
      end

      context "nonpriority appeals with SCT appeals" do
        subject { DirectReviewDocket.new.distribute_appeals(distribution, priority: false, limit: limit) }

        it "creates distributed cases, judge tasks, and specialty case team tasks" do
          tasks = subject

          # We expect as many as the limit of appeals + the number of sct_appeals
          expect(tasks.length).to eq(10)
          expect(tasks.first.class).to eq(DistributedCase)
          expect(distribution.distributed_cases.length).to eq(10)
          expect(judge_user.reload.tasks.map(&:appeal)).to include(appeals.first)
          expect(distribution.distributed_cases.count(&:sct_appeal)).to eq(5)
        end
      end

      context "EvidenceSubmissionDocket with nonpriority appeals with SCT appeals " do
        let(:docket_type) { Constants.AMA_DOCKETS.evidence_submission }

        before do
          # Complete the EvidenceSubmissionWindowTask to move the appeals to be ready to distribute
          appeals.each do |appeal|
            appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first.completed!
          end
          CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_evidence_submission_docket_time_goals)
            .update!(value: 61)
        end

        subject { EvidenceSubmissionDocket.new.distribute_appeals(distribution, priority: false, limit: limit) }

        it "creates distributed cases, judge tasks, and specialty case team tasks" do
          tasks = subject

          # We expect as many as the limit of appeals + the number of sct_appeals
          expect(tasks.length).to eq(10)
          expect(tasks.first.class).to eq(DistributedCase)
          expect(distribution.distributed_cases.length).to eq(10)
          expect(judge_user.reload.tasks.map(&:appeal)).to include(appeals.first)
          expect(distribution.distributed_cases.count(&:sct_appeal)).to eq(5)
        end
      end
    end

    context "nonpriority appeals with SCT feature toggle disabled" do
      before do
        FeatureToggle.disable!(:specialty_case_team_distribution)
      end

      subject { DirectReviewDocket.new.distribute_appeals(distribution, priority: false, limit: limit) }

      it "creates distributed cases and judge tasks" do
        tasks = subject

        # We expect as many as the limit of appeals with no additional sct appeals or tasks
        expect(tasks.length).to eq(5)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(distribution.distributed_cases.length).to eq(5)
        expect(judge_user.reload.tasks.map(&:appeal)).to include(appeals.first)
        expect(distribution.distributed_cases.count(&:sct_appeal)).to eq(0)
      end
    end
  end

  context "distribute appeals when CAVC cases don't have an appeal_affinity record" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:distribution) { Distribution.create!(judge: judge) }
    let!(:cavc_appeal_with_appeal_affinity) do
      appeal = create_ready_cavc_appeal_without_appeal_affinity(tied_judge: judge, created_date: 7.days.ago)
      create(:appeal_affinity, appeal: appeal)
      appeal
    end
    let!(:cavc_appeal_no_appeal_affinity) do
      create_ready_cavc_appeal_without_appeal_affinity(tied_judge: judge, created_date: 7.days.ago)
    end

    before do
      FeatureToggle.enable!(:acd_exclude_from_affinity)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end

    subject { DirectReviewDocket.new.distribute_appeals(distribution, priority: true, limit: 3) }

    it "selects all appeals tied to the requesting judge" do
      expect(subject.map(&:case_id)).to match_array([cavc_appeal_with_appeal_affinity.uuid,
                                                     cavc_appeal_no_appeal_affinity.uuid])
    end
  end

  def create_ready_cavc_appeal_without_appeal_affinity(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date - 6.months)
    if tied_judge
      judge = tied_judge
      attorney = JudgeTeam.for_judge(judge)&.attorneys&.first || create(:user, :with_vacols_attorney_record)
    else
      judge = create(:user, :judge, :with_vacols_judge_record)
      attorney = create(:user, :with_vacols_attorney_record)
    end

    source_appeal = create(
      :appeal,
      :direct_review_docket,
      :dispatched,
      associated_judge: judge,
      associated_attorney: attorney
    )

    Timecop.travel(6.months.from_now)
    cavc_remand = create(
      :cavc_remand,
      source_appeal: source_appeal
    )
    remand_appeal = cavc_remand.remand_appeal
    distribution_tasks = remand_appeal.tasks.select { |task| task.is_a?(DistributionTask) }
    (distribution_tasks.flat_map(&:descendants) - distribution_tasks).each(&:completed!)
    Timecop.return

    remand_appeal
  end
end
