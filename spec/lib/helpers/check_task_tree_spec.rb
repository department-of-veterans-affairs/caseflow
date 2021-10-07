# frozen_string_literal: true

require "helpers/check_task_tree"

describe "CheckTaskTree" do
  let(:errors) { CheckTaskTree.call(appeal, verbose: false).first }
  let(:appeal) { create(:appeal) }

  describe "CheckTaskTree#patch_classes" do
    before do
      CheckTaskTree.patch_classes
    end
    subject { appeal.check_task_tree(verbose: false) }
    it "calls CheckTaskTree.check" do
      expect_any_instance_of(CheckTaskTree).to receive(:check).and_call_original
      errors, warnings = subject
      expect(errors).to include "Appeal is stuck"
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
  end

  context "check_parent_child_tasks" do
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
      let(:appeal) { create(:appeal, :ready_for_distribution) }
      it_behaves_like "when tasks are correct"
      
      context "when tasks are invalid" do
        before { appeal.root_task.completed! }
        it { is_expected.not_to be_blank }
        include_examples "has error message", "Closed RootTask should not have open tasks"
      end
    end
    describe "#active_tasks_with_open_root_task" do
      subject { CheckTaskTree.new(appeal).active_tasks_with_open_root_task }
      let(:appeal) { create(:appeal, :ready_for_distribution) }
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
  end

  context "check_task_counts" do
    describe "#extra_open_hearing_tasks" do
      subject { CheckTaskTree.new(appeal).extra_open_hearing_tasks }
      let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
      it_behaves_like "when tasks are correct"
      
      context "when tasks are invalid" do
        before { HearingTask.create!(appeal: appeal, parent: appeal.root_task) }
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
        include_examples "has error message", /There should be no more than 1 open task of type/
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
end
