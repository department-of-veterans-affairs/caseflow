# frozen_string_literal: true

describe SCTAssignTaskCreator do
  describe "#call" do
    let(:appeal) do
      create(:appeal, :with_post_intake_tasks, :with_vha_issue, docket_type: Constants.AMA_DOCKETS.direct_review)
    end

    context "when an appeal does not have an open sct task" do
      let(:assigned_by_id) { 2 }
      subject { SCTAssignTaskCreator.new(appeal: appeal, assigned_by_id: assigned_by_id).call }

      it "creates an sct assign task" do
        subject
        sct_task = SpecialtyCaseTeamAssignTask.find_by(appeal: appeal)
        expect(sct_task.appeal).to eq(appeal)
        expect(sct_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(sct_task.assigned_to_type).to eq("Organization")
      end
    end
  end
end
