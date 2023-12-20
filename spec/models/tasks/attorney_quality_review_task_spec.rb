# frozen_string_literal: true

describe AttorneyQualityReviewTask, :all_dbs do
  context ".create" do
    it "returns the correct label" do
      expect(AttorneyQualityReviewTask.new.label).to eq(
        COPY::ATTORNEY_QUALITY_REVIEW_TASK_LABEL
      )
    end

    it "returns the correct timeline title" do
      expect(AttorneyQualityReviewTask.new.timeline_title).to eq(
        COPY::CASE_TIMELINE_ATTORNEY_QUALITY_REVIEW_TASK
      )
    end
  end

  context "when cancelling the task" do
    let(:atty) { create(:user) }
    let(:judge) { create(:user) }
    let!(:atty_staff) { create(:staff, :attorney_role, sdomainid: atty.css_id) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let(:parent) { create(:ama_judge_dispatch_return_task) }
    let!(:task) do
      create(:ama_attorney_dispatch_return_task, assigned_by: judge, assigned_to: atty, parent: parent)
    end

    subject { task.update!(status: Constants.TASK_STATUSES.cancelled) }

    it "cancels the task and moves the parent back to the judge's queue" do
      expect(subject).to be true
      expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(parent.reload.status).to eq Constants.TASK_STATUSES.assigned
    end
  end
end
