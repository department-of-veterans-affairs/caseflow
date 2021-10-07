# frozen_string_literal: true

require "helpers/check_task_tree"

describe "CheckTaskTree" do
  let(:appeal) { create(:appeal) }

  describe "#check" do
    context "..." do
      let(:appeal) { create(:appeal, :with_evidence_submission_window_task) }
      it "..." do
        errors, warnings = subject
        appeal.treee
        # binding.pry
      end
    end
  end
  let(:errors) { CheckTaskTree.new(appeal).check(verbose: false).first }

  describe "#open_tasks_with_parent_not_on_hold" do
    subject { CheckTaskTree.new(appeal).open_tasks_with_parent_not_on_hold }
    let(:appeal) { create(:appeal, :mail_blocking_distribution) }
    context "when tasks are valid" do
      it { is_expected.to be_blank }
      it "returns no errors" do expect(errors).to be_empty end
    end
    context "when tasks are invalid" do
      before { appeal.tasks.of_type(:DistributionTask).first.assigned! }
      it { is_expected.to eq [appeal.tasks.open.last] }
      it "returns errors" do
        expect(errors).to include "Open task should have an on_hold parent task"
      end
    end
  end
  describe "#open_tasks_with_closed_root_task" do
    subject { CheckTaskTree.new(appeal).open_tasks_with_closed_root_task }
    let(:appeal) { create(:appeal, :ready_for_distribution) }
    context "when tasks are valid" do
      it { is_expected.to be_blank }
    end
    context "when tasks are invalid" do
      before { appeal.root_task.completed! }
      it { is_expected.to eq [appeal.tasks.open.last] }
      it "returns errors" do
        expect(errors).to include "Closed RootTask should not have open tasks"
      end
    end
  end
  describe "#active_tasks_with_open_root_task" do
    subject { CheckTaskTree.new(appeal).active_tasks_with_open_root_task }
    let(:appeal) { create(:appeal, :ready_for_distribution) }
    before { TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: create(:vso)) }
    context "when tasks are valid" do
      it { is_expected.not_to be_blank }
      it "returns no errors" do expect(errors).to be_empty end
    end
    context "when tasks are invalid" do
      before { appeal.root_task.completed! }
      it { is_expected.to be_blank }
      it "returns errors" do
        expect(errors).to include "Open RootTask should have at least one 'proper' active task"
      end
    end
  end
  describe "#extra_open_hearing_tasks" do
    subject { CheckTaskTree.new(appeal).extra_open_hearing_tasks }
    let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
    context "when tasks are valid" do
      it { is_expected.to be_blank }
      it "returns no errors" do expect(errors).to be_empty end
    end
    context "when tasks are invalid" do
      before { HearingTask.create!(appeal: appeal, parent: appeal.root_task) }
      it { is_expected.not_to be_blank }
      it "returns errors" do
        expect(errors).to include "There should be no more than 1 open HearingTask"
      end
    end
  end
  describe "#extra_open_tasks" do
    subject { CheckTaskTree.new(appeal).extra_open_tasks }
    let(:appeal) { create(:appeal, :at_bva_dispatch) }
    context "when tasks are valid" do
      it { is_expected.to be_blank }
      it "returns no errors" do expect(errors).to be_empty end
    end
    context "when tasks are invalid" do
      let(:dispatch_task) { appeal.tasks.assigned_to_any_user.find_by_type(:BvaDispatchTask) }
      let(:judge) { appeal.tasks.assigned_to_any_user.find_by_type(:JudgeDecisionReviewTask).assigned_to }
      before do
        JudgeDispatchReturnTask.create!(appeal: appeal, parent: dispatch_task, assigned_to: judge)
        JudgeDispatchReturnTask.create!(appeal: appeal, parent: dispatch_task, assigned_to: judge)
      end
      it { is_expected.not_to be_blank }
      it "returns errors" do
        expect(errors).to include "There should be no more than 1 open task"
      end
    end
  end
end
