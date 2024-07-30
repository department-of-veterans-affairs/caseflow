# frozen_string_literal: true

describe BvaIntakePendingTab, :postgres do
  let(:tab) { BvaIntakePendingTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { BvaIntake.singleton }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a BvaIntakePendingTab" do
      let(:params) { { assignee: assignee } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_ready_to_review) { create_list(:pre_docket_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_completed_tasks) { create_list(:pre_docket_task, 3, :completed, assigned_to: assignee) }

      it "does not return assignee's ready for review tasks" do
        expect(subject).to match_array([])
      end

      it "does not return assignee's completed tasks" do
        expect(subject).to match_array([])
      end
    end

    context "when a PreDocketTask has child tasks" do
      let!(:child_tasks) do
        create_list(:education_document_search_task, 4, :assigned, assigned_to: EducationEmo.singleton)
      end
      let!(:rpo_office) { create(:education_rpo) }

      it "only the active children are shown" do
        completed_sibling = child_tasks.first
        completed_sibling.completed!

        active_sibling = EducationDocumentSearchTask.create!(
          appeal: completed_sibling.appeal,
          parent: completed_sibling.parent,
          assigned_at: Time.zone.now,
          assigned_to: EducationEmo.singleton
        )

        expect(subject).to include active_sibling
        expect(subject).to_not include completed_sibling
      end

      it "tasks with 'grandchildren' are still returned" do
        first_child_task = child_tasks.first

        EducationAssessDocumentationTask.create!(
          appeal: first_child_task.appeal,
          parent: first_child_task,
          assigned_at: Time.zone.now,
          assigned_to: rpo_office
        )

        expect(subject).to match_array(child_tasks)
      end
    end

    context "when the assignee is a user" do
      let(:assignee) { create(:user) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end
  end
end
