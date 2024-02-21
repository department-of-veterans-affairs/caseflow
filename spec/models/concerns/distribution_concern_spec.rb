# frozen_string_literal: true

describe DistributionConcern do
  class DistributionConcernTestClass
    include ActiveModel::Model
    include DistributionConcern
  end

  before(:each) do
    @concern_test_class = DistributionConcernTestClass.new
  end

  context "#assign_judge_tasks_for_appeals" do
    let!(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:appeals) { [] }
    let(:appeal_open_dist_task) { create(:appeal, :direct_review_docket, :ready_for_distribution) }
    let(:appeal_open_dist_and_non_blocking_task) do
      appeal = create(:appeal, :direct_review_docket, :ready_for_distribution)
      create(:evidence_or_argument_mail_task, assigned_to: MailTeam.singleton, parent: appeal.root_task)

      appeal
    end
    let(:appeal_open_dist_and_blocking_task) do
      appeal = create(:appeal, :direct_review_docket, :ready_for_distribution)
      create(:task, assigned_to: PrivacyTeam.singleton, parent: appeal.root_task, appeal: appeal)

      appeal.reload
    end
    let(:appeal_no_open_dist_task) { create(:appeal, :assigned_to_judge, associated_judge: judge) }

    subject { @concern_test_class }

    context "for appeals with an open distribution task" do
      context "if can_redistribute_appeal? is true" do
        let!(:appeals) { [appeal_open_dist_task, appeal_open_dist_and_non_blocking_task] }

        it "a JudgeAssignTask is created" do
          result = subject.send :assign_judge_tasks_for_appeals, appeals, judge

          expect(result[0].is_a?(JudgeAssignTask)).to be true
          expect(result[1].is_a?(JudgeAssignTask)).to be true
        end
      end

      context "if can_redistribute_appeal? is false" do
        let!(:appeals) { [appeal_open_dist_and_blocking_task] }

        it "appeals are skipped and return nil" do
          result = subject.send :assign_judge_tasks_for_appeals, appeals, judge

          expect(result.first).to be nil
        end
      end
    end

    context "for appeals with no open distribution task" do
      context "if can_redistribute_appeal? is true" do
        let!(:appeals) { [appeal_no_open_dist_task] }

        it "appeals are skipped and return nil " do
          result = subject.send :assign_judge_tasks_for_appeals, appeals, judge

          expect(result.first).to be nil
        end
      end
    end
  end

  context "#cancel_previous_judge_assign_task" do
    let!(:appeal) do
      appeal = create(:appeal, :direct_review_docket, :ready_for_distribution)
      create(:ama_judge_assign_task, :assigned, assigned_to: original_judge, appeal: appeal, parent: appeal.root_task)
      create(
        :ama_judge_assign_task,
        :assigned,
        assigned_to: distribution_judge,
        appeal: appeal,
        parent: appeal.root_task,
        skip_check_for_only_open_task_of_type: true
      )

      appeal.reload
    end
    let(:original_judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution_judge) { create(:user, :judge, :with_vacols_judge_record) }

    subject { @concern_test_class }
    context "when an appeal already has an open JudgeAssignTask" do
      it "will cancel the one not assigned to the distribution judge" do
        subject.send :cancel_previous_judge_assign_task, appeal, distribution_judge.id

        expect(appeal.tasks.where(type: JudgeAssignTask.name).size).to eq 2
        expect(appeal.tasks.where(type: JudgeAssignTask.name).first.status).to eq "cancelled"
        expect(appeal.tasks.where(type: JudgeAssignTask.name).last.status).to eq "assigned"
        expect(appeal.tasks.where(type: JudgeAssignTask.name).last.assigned_to_id).to eq distribution_judge.id
      end
    end
  end
end
