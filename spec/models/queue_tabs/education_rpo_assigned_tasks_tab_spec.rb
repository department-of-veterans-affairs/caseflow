# frozen_string_literal: true

describe EducationRpoAssignedTasksTab, :postgres do
  let(:tab) { EducationRpoAssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_rpo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationRpoAssignedTasksTab" do
      let(:params) { { assignee: create(:education_rpo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(5)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks assigned to rpo" do
      let!(:assignee_active_tasks) do
        create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee)
      end

      it "returns assigned tasks" do
        expect(subject).to match_array(assignee_active_tasks)
      end
    end
    context "the appeal does not appear on the RPO Assigned tab " do
      let!(:assignee_active_tasks) do
        create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee)
      end

      it "when sent to EMO " do
        sent_to_emo = assignee_active_tasks.first

        # Simulate sending task back to the EMO
        sent_to_emo.update!(status: Constants.TASK_STATUSES.completed)
        sent_to_emo.parent.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 3
        expect(subject).not_to include sent_to_emo
      end

      it "when sent to Bva Intake" do
        sent_to_bva_intake = assignee_active_tasks.first
        emo_task = sent_to_bva_intake.parent
        bva_intake_task = emo_task.parent

        # Simulate sending task to BVA Intake for Review
        sent_to_bva_intake.update!(status: Constants.TASK_STATUSES.completed)
        emo_task.update!(status: Constants.TASK_STATUSES.completed)
        bva_intake_task.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 3
        expect(subject).not_to include sent_to_bva_intake
      end

      it "when an RPO task is set to in progress" do
        in_progress_task = assignee_active_tasks.first

        # Set one of the RPO tasks to in_progress
        in_progress_task.update!(status: Constants.TASK_STATUSES.in_progress)

        expect(subject.count).to eq 3
        expect(subject).not_to include in_progress_task
      end
    end
  end
end
