# frozen_string_literal: true

describe EducationEmoCompletedTasksTab, :postgres do
  let(:tab) { EducationEmoCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_emo) }
  let(:education_rpo) { create(:education_rpo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationEmoCompletedTasksTab" do
      let(:params) { { assignee: create(:education_emo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(6)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when the EMO sends an appeal to BVA Intake" do
      let!(:assignee_completed_task) { create(:education_document_search_task, :completed, assigned_to: assignee) }

      it("the appeal appears in the EMO completed tab whenever BVA Intake dockets it") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.completed)

        expect(subject.count).to_not eq 0
      end

      it("the appeal does not appear in the EMO completed tab whenever
        BVA Intake has not taken any additional actions") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 0
      end

      it("the appeal does not appear in the EMO completed tab whenever BVA Intake cancels it") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.cancelled)

        expect(subject.count).to eq 0
      end
    end
  end
end
