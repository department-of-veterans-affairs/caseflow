# frozen_string_literal: true

require_relative "../../app/models/tasks/mail_task"

describe Docket, :all_dbs do
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
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end

    context "docket type" do
      # docket_type is implemented in the subclasses and should error if called here
      context "when docket type is called directly" do
        subject { Docket.new.docket_type }
        it "throws an error" do
          expect { subject }.to raise_error(Caseflow::Error::MustImplementInSubclass)
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
            expect(subject.count.size).to eq 0
          end
        end

        context "when called for the judge with affinity" do
          let(:judge) { judge_decision_review_task.assigned_to }
          subject { DirectReviewDocket.new.appeals(ready: true, genpop: "not_genpop", judge: judge) }

          it "returns only the cavc appeal" do
            expect(subject).to match_array([cavc_appeal])
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

        context "nonblocking mail tasks but closed Root Task" do
          it "excludes those appeals" do
            inactive_appeal = create(:appeal,
                                     :with_post_intake_tasks,
                                     docket_type: Constants.AMA_DOCKETS.direct_review)
            AodMotionMailTask.create_from_params({
                                                   appeal: inactive_appeal,
                                                   parent_id: inactive_appeal.root_task.id
                                                 }, user)
            inactive_appeal.root_task.update!(status: "completed")

            expect(subject).to_not include inactive_appeal
          end
        end
      end
    end

    context "count" do
      let(:priority) { nil }
      subject { DirectReviewDocket.new.count(priority: priority) }

      it "counts appeals" do
        expect(subject).to eq(6)
      end

      context "when looking for nonpriority appeals" do
        let(:priority) { false }
        it "counts nonpriority appeals" do
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
    end

    context "age_of_n_oldest_genpop_priority_appeals" do
      subject { DirectReviewDocket.new.age_of_n_oldest_genpop_priority_appeals(1) }

      it "returns the 'ready at' field of the oldest priority appeals that are ready for distribution" do
        expect(subject.length).to eq(1)
        expect(subject.first).to eq(aod_age_appeal.ready_for_distribution_at)
      end
    end

    context "age_of_n_oldest_priority_appeals_available_to_judge" do
      let(:judge) { create(:user, :with_vacols_judge_record) }

      subject { DirectReviewDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(judge, 5) }

      it "returns the receipt_date field of the oldest direct review priority appeals ready for distribution" do
        expect(subject.length).to eq(3)
        expect(subject).to eq([aod_age_appeal.receipt_date, aod_motion_appeal.receipt_date, cavc_appeal.receipt_date])
      end
    end

    context "age_of_n_oldest_nonpriority_appeals_available_to_judge" do
      let(:judge) { create(:user, :with_vacols_judge_record) }

      subject { DirectReviewDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, 5) }

      it "returns the receipt_date field of the oldest direct review priority appeals ready for distribution" do
        expect(subject.length).to eq(3)
        expect(subject).to eq(
          [appeal.receipt_date, denied_aod_motion_appeal.receipt_date, inapplicable_aod_motion_appeal.receipt_date]
        )
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

        before do
          cavc_distribution_task.update!(assigned_at: (Constants.DISTRIBUTION.cavc_affinity_days + 1).days.ago)
        end

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
        task: distributed_appeal.tasks.of_type("DistributionTask").first
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
end
