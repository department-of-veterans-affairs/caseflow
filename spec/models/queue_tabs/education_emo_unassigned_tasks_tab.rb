# frozen_string_literal: true

describe EducationEmoUnassignedTasksTab, :postgres do
  let(:tab) { EducationEmoUnassignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_emo) }
  let(:rpo_assignee) { create(:edu_regional_processing_office) }
  

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationEmoUnassignedTasksTab" do
      let(:params) { { assignee: create(:education_emo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when the EMO initially receives a pre-docketed education appeal" do
      let!(:assignee_assigned_task) { create(:education_document_search_task, :assigned, assigned_to: assignee) }

      it "returns appeal that has not been worked on by the EMO and is still assigned" do
        expect(subject.to_a.first).to eq(assignee_assigned_task)
      end
    end

    context "when the RPO task is cancelled and sent back to the EMO" do
      let!(:assignee_assigned_task) { create(:education_document_search_task, :assigned, assigned_to: assignee) }
      let!(:assignee_assigned_task_child) { create(:education_assess_documentation_task, :cancelled, assigned_to: rpo_assignee, parent: assignee_assigned_task) }
      
      it "returns the appeal that was cancelled by the RPO and is now assigned in EMO" do
        assignee_assigned_task.update!(status:Constants.TASK_STATUSES.assigned)
        expect(subject.to_a.first).to eq(assignee_assigned_task)
      end
    end

    context "when the EMO task is completed, BVA receives the appeal, and then sends it back to EMO" do
      let!(:assignee_assigned_task) { create(:education_document_search_task, :assigned, assigned_to: assignee) }
      let!(:assignee_assigned_task_child) { create(:education_assess_documentation_task, :completed, assigned_to: rpo_assignee, parent: assignee_assigned_task) }

      it "returns the appeal that has tasks completed by RPO and EMO, and then is assigned again to EMO" do
        assignee_assigned_task.update!(status:Constants.TASK_STATUSES.completed)
        create(:education_document_search_task, :assigned, assigned_to: assignee, parent: assignee_assigned_task.parent)
        expect(subject.to_a.first).to eq(assignee_assigned_task.siblings.first)
      end
    end
  end
end