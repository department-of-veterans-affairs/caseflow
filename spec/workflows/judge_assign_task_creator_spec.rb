# frozen_string_literal: true

describe JudgeAssignTaskCreator do
  describe "#call" do
    context "when an appeal has an open judge assign task and an open distribution task" do
      let(:appeal) do
        create(:appeal, :evidence_submission_docket, :assigned_to_judge, associated_judge: first_judge)
      end

      let!(:first_judge) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_J") }
      let!(:first_judge_staff) { create(:staff, :judge_role, sdomainid: first_judge.css_id) }

      let!(:second_judge) { create(:user, :with_vacols_judge_record, full_name: "Judge Mathis", css_id: "JUDGE_M") }
      let!(:second_judge_staff) { create(:staff, :judge_role, sdomainid: second_judge.css_id) }
      let(:assigned_by_id) { nil }

      subject { JudgeAssignTaskCreator.new(appeal: appeal, judge: second_judge, assigned_by_id: assigned_by_id).call }

      before do
        appeal.tasks.find_by_type(:DistributionTask).assigned!
      end
      it "cancels the first judge assign task and makes a new one" do
        subject

        first_judge_task = JudgeAssignTask.find_by(assigned_to: first_judge.id)
        second_judge_task = JudgeAssignTask.find_by(assigned_to: second_judge.id)

        expect(first_judge_task.id).not_to eq(second_judge_task)
        expect(first_judge_task.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(second_judge_task.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end
  end
end
