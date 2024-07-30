# frozen_string_literal: true

require "helpers/check_task_tree"

describe "CheckTaskTree" do
  let(:errors) { CheckTaskTree.call(appeal, verbose: false).first }
  let(:appeal) { create(:appeal) }

  context "when run against a legacy appeal" do
    let(:legacy_appeal) { create(:legacy_appeal) }
    subject { CheckTaskTree.new(legacy_appeal).check }
    it "aborts with message and returns nil" do
      expect { subject }.to output(/This checker is only for AMA appeals/).to_stdout
      expect(subject).to eq nil
    end
  end

  describe "CheckTaskTree#patch_classes" do
    before do
      CheckTaskTree.patch_classes
    end
    subject { appeal.check_task_tree(verbose: false) }
    it "calls CheckTaskTree.check" do
      expect_any_instance_of(CheckTaskTree).to receive(:check).and_call_original
      errors, warnings = subject
      expect(errors).to include "There should be at least 1 task"
      expect(warnings).to eq []
    end
  end

  shared_examples "when tasks are correct" do
    it { is_expected.to be_blank }
    it "returns no errors" do
      expect(errors).to be_empty
    end
  end
  shared_examples "has error message" do |error_msg|
    it "returns errors" do
      expect(errors).to include error_msg
    end
  end

  let(:distribution_task) { appeal.tasks.find_by_type(:DistributionTask) }
  context "check_task_attributes" do
    let(:appeal) { create(:appeal, :ready_for_distribution) }

    describe "#open_tasks_with_closed_at_defined" do
      subject { CheckTaskTree.new(appeal).open_tasks_with_closed_at_defined }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before do
          distribution_task.cancelled!
          distribution_task.update_columns(status: :assigned)
        end
        it { is_expected.to eq [distribution_task] }
        include_examples "has error message", "Open task should have nil `closed_at`"
      end
    end
    describe "#closed_tasks_without_closed_at" do
      subject { CheckTaskTree.new(appeal).closed_tasks_without_closed_at }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before do
          distribution_task.cancelled!
          distribution_task.update_columns(closed_at: nil)
        end
        it { is_expected.to eq [distribution_task] }
        include_examples "has error message", "Closed task should have non-nil `closed_at`"
      end
    end

    describe "#open_tasks_with_cancelled_by_defined" do
      subject { CheckTaskTree.new(appeal).open_tasks_with_cancelled_by_defined }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before do
          distribution_task.update(cancelled_by: create(:user))
        end
        it { is_expected.to eq [distribution_task] }
        include_examples "has error message", "Open task should have nil `cancelled_by_id`"
      end
    end
    describe "#cancelled_tasks_without_cancelled_by" do
      subject { CheckTaskTree.new(appeal).cancelled_tasks_without_cancelled_by }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before do
          distribution_task.cancelled!
          distribution_task.update(cancelled_by: nil)
        end
        it { is_expected.to eq [distribution_task] }
        include_examples "has error message", "Cancelled task should have non-nil `cancelled_by_id`"
      end
    end

    describe "#open_tasks_with_inactive_assignee" do
      subject { CheckTaskTree.new(appeal).open_tasks_with_inactive_assignee }
      let(:assignee) { create(:vso) }
      before do
        TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: assignee)
      end
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        let(:assignee) { create(:vso, status: :inactive) }
        it { is_expected.not_to be_blank }
        include_examples "has error message", "Open task should not be assigned to inactive assignee"
      end
    end

    describe "#inconsistent_assignees" do
      subject { CheckTaskTree.new(appeal).inconsistent_assignees }
      let(:appeal) { create(:appeal, :ready_for_distribution) }
      it_behaves_like "when tasks are correct"

      context "when DistributionTask is invalid" do
        before do
          distribution_task.update(assigned_to: QualityReview.singleton)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message",
                         /Task assignee is inconsistent with other tasks of the same type: .*DistributionTask/
      end
      context "when ScheduleHearingTask for AMA appeal is invalid" do
        let(:appeal) { create(:appeal, :ready_for_distribution, :with_schedule_hearing_tasks) }
        let(:hearing_task) { appeal.tasks.find_by_type(:HearingTask) }
        let(:schedule_hearing_task) { appeal.tasks.find_by_type(:ScheduleHearingTask) }
        before do
          hearing_task.update(parent: distribution_task)
          distribution_task.update(status: :on_hold)
          schedule_hearing_task.update(assigned_to: QualityReview.singleton)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message",
                         /Task assignee is inconsistent with other tasks of the same type: .*ScheduleHearingTask/
      end
    end

    describe "#track_veteran_task_assigned_to_non_representative" do
      subject { CheckTaskTree.new(appeal).track_veteran_task_assigned_to_non_representative }
      let!(:tv_task) { create(:track_veteran_task, parent: appeal.root_task, assigned_to: create(:vso)) }
      it_behaves_like "when tasks are correct"

      context "when TrackVeteranTask is invalid" do
        before do
          tv_task.update(assigned_to: Bva.singleton)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message", /TrackVeteranTask assignee should be a Representative/
      end
    end
  end

  context "check_parent_child_tasks" do
    let(:appeal) { create(:appeal, :ready_for_distribution) }
    describe "#open_tasks_with_parent_not_on_hold" do
      subject { CheckTaskTree.new(appeal).open_tasks_with_parent_not_on_hold }
      let(:appeal) { create(:appeal, :mail_blocking_distribution) }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before { appeal.tasks.of_type(:DistributionTask).first.assigned! }
        it { is_expected.to eq [appeal.tasks.open.last] }
        include_examples "has error message", "Open task should have an on_hold parent task"
      end
    end
    describe "#open_tasks_with_closed_root_task" do
      subject { CheckTaskTree.new(appeal).open_tasks_with_closed_root_task }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before { appeal.root_task.completed! }
        it { is_expected.not_to be_blank }
        include_examples "has error message", "Closed RootTask should not have open tasks"
      end
    end
    describe "#active_tasks_with_open_root_task" do
      subject { CheckTaskTree.new(appeal).active_tasks_with_open_root_task }
      before { TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: create(:vso)) }
      context "when tasks are correct" do
        it { is_expected.not_to be_blank }
        it "returns no errors" do
          expect(errors).to be_empty
        end
      end
      context "when tasks are invalid" do
        before { distribution_task.completed! }
        it { is_expected.to be_blank }
        include_examples "has error message", "Open RootTask should have an active task assigned to the Board"
      end
    end
    describe "#unexpected_child_tasks" do
      subject { CheckTaskTree.new(appeal).unexpected_child_tasks }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      let(:judge) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask).assigned_to }
      let(:dispatch_org_task) { appeal.tasks.assigned_to_any_org.find_by_type(:BvaDispatchTask) }
      it_behaves_like "when tasks are correct"
      context "when tasks are invalid" do
        before do
          JudgeDispatchReturnTask.create!(appeal: appeal, parent: dispatch_org_task, assigned_to: judge)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message", /Unexpected child task: .*JudgeDispatchReturnTask/
      end
    end
    describe "#tasks_with_unexpected_parent_task" do
      subject { CheckTaskTree.new(appeal).tasks_with_unexpected_parent_task }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      let(:judge) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask).assigned_to }
      let(:dispatch_org_task) { appeal.tasks.assigned_to_any_org.find_by_type(:BvaDispatchTask) }
      let(:dispatch_user_task) { appeal.tasks.assigned_to_any_user.find_by_type(:BvaDispatchTask) }
      it_behaves_like "when tasks are correct"
      context "when tasks are invalid" do
        before do
          dispatch_user_task.update(parent: appeal.root_task)
          dispatch_org_task.assigned!
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message", /Unexpected parent task for: .*BvaDispatchTask/
      end
    end
  end

  context "check_task_counts" do
    context "when appeal has 0 tasks" do
      include_examples "has error message", "There should be at least 1 task"
    end
    context "when an appeal only has a RootTask" do
      let(:appeal) { create(:appeal, :active) }
      include_examples "has error message", "Active appeal should have at least 1 non-RootTask task"
    end
    context "established appeal without DistributionTask" do
      include_examples "has error message", "Established appeal should have a DistributionTask"
    end
    context "dispatched appeal has open RootTask" do
      let(:appeal) { create(:appeal, :dispatched) }
      before { appeal.root_task.on_hold! }
      include_examples "has error message", "Dispatched appeal (with decision document) should not have open RootTask"
    end

    describe "#extra_open_hearing_tasks" do
      subject { CheckTaskTree.new(appeal).extra_open_hearing_tasks }
      let(:appeal) { create(:appeal, :ready_for_distribution, :with_schedule_hearing_tasks) }
      let(:hearing_task) { appeal.tasks.find_by_type(:HearingTask) }
      before do
        hearing_task.update(parent: distribution_task)
        distribution_task.on_hold!
      end
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before { HearingTask.create!(appeal: appeal, parent: distribution_task) }
        it { is_expected.not_to be_blank }
        include_examples "has error message", "There should be no more than 1 open HearingTask"
      end
    end
    describe "#extra_open_tasks" do
      subject { CheckTaskTree.new(appeal).extra_open_tasks }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        let(:dispatch_task) { appeal.tasks.assigned_to_any_user.find_by_type(:BvaDispatchTask) }
        let(:judge) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask).assigned_to }
        before do
          JudgeDispatchReturnTask.create!(appeal: appeal, parent: dispatch_task, assigned_to: judge)
          JudgeDispatchReturnTask.create!(appeal: appeal, parent: dispatch_task, assigned_to: judge)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message",
                         /There should be no more than 1 open task of type .*JudgeDispatchReturnTask/
      end
    end
    describe "#extra_open_org_tasks" do
      subject { CheckTaskTree.new(appeal).extra_open_org_tasks }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        let(:dispatch_task) { appeal.tasks.assigned_to_any_user.find_by_type(:BvaDispatchTask) }
        let(:judge) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask).assigned_to }
        before do
          dispatch_task.completed!
          org_task = appeal.tasks.assigned_to_any_org.find_by_type(:BvaDispatchTask)
          org_task.cancelled!
          BvaDispatchTask.create(appeal: appeal, parent: appeal.root_task, assigned_to: BvaDispatch.singleton)
          org_task.assigned!
          org_task.update(cancelled_by_id: nil)
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message", /There should be no more than 1 open org task of type .*BvaDispatchTask/
      end
    end
    describe "#open_exclusive_root_children_tasks" do
      subject { CheckTaskTree.new(appeal).open_exclusive_root_children_tasks }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      context "when tasks are correct" do
        it "returns no errors" do
          expect(errors).to be_empty
        end
      end

      context "when tasks are invalid" do
        let(:judge_task) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask) }
        before { judge_task.assigned! }
        it { is_expected.not_to be_blank }
        include_examples "has error message",
                         /There should be no more than 1 open among these root-children tasks:.*JudgeDecisionReviewTask/
      end
    end
  end

  describe "#open_tasks_with_no_active_issues" do
    subject { CheckTaskTree.new(appeal).open_tasks_with_no_active_issues }
    let(:appeal) { create(:appeal, :dispatched) }
    let(:education) { create(:business_line, url: "education") }
    let!(:request_issue) { create(:request_issue, :decided, decision_review: appeal) }
    let(:review_task) { DecisionReviewTask.create!(appeal: appeal, assigned_to: education) }
    before do
      review_task.cancelled!
      review_task.update(cancelled_by: create(:user))
      BoardGrantEffectuationTask.create!(appeal: appeal, assigned_to: education)
    end
    it_behaves_like "when tasks are correct"

    context "when tasks are invalid" do
      let(:review_task) { DecisionReviewTask.create!(appeal: appeal, assigned_to: education) }
      before do
        review_task.assigned!
      end
      it { is_expected.not_to be_blank }
      include_examples "has error message", "Task should be closed since there are no active issues"
    end
  end

  describe "#open_task_timers_for_closed_tasks" do
    subject { CheckTaskTree.new(appeal).open_task_timers_for_closed_tasks }
    let(:appeal) { create(:appeal, :assigned_to_judge) }
    let(:judge_task) { appeal.tasks.find_by_type(:JudgeAssignTask) }
    let!(:task_timer) { create(:task_timer, task: judge_task) }
    it_behaves_like "when tasks are correct"

    context "when tasks are invalid" do
      before do
        judge_task.cancelled!
        task_timer.update_columns(canceled_at: nil)
      end
      it { is_expected.not_to be_blank }
      include_examples "has error message", "Closed task should not have processable TaskTimer"
    end
  end

  context "check_task_prerequisites" do
    describe "#missing_dispatch_task_prerequisite" do
      subject { CheckTaskTree.new(appeal).missing_dispatch_task_prerequisite }
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      let(:jdr_task) { appeal.tasks.find_by_type(:JudgeDecisionReviewTask) }
      it_behaves_like "when tasks are correct"

      context "when tasks are invalid" do
        before do
          jdr_task.destroy
        end
        it { is_expected.not_to be_blank }
        include_examples "has error message", "BvaDispatchTask requires [\"completed JudgeDecisionReviewTask\"]"
      end
    end
  end
end
