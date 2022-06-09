# frozen_string_literal: true

describe EducationRpoInProgressTasksTab, :postgres do
  let(:tab) { EducationRpoInProgressTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_rpo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationRpoInProgressTasksTab" do
      let(:params) { { assignee: create(:education_rpo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks in progress with the assignee and other folks" do
      let!(:assignee_in_progress_tasks) do
        create_list(:education_assess_documentation_task, 5, :in_progress, assigned_to: assignee)
      end
      let!(:other_in_progress_tasks) { create_list(:education_assess_documentation_task, 9) }

      it "returns in progress tasks of the assignee and not any other folks" do
        expect(subject).to match_array(
          [assignee_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [other_in_progress_tasks].flatten
        )
      end

      context "when there are tasks assigned to the assignee" do
        let!(:assignee_assigned_tasks) do
          create_list(:education_assess_documentation_task, 5, :assigned, assigned_to: assignee)
        end

        it "does not return the assigned tasks" do
          expect(subject).not_to include(
            [assignee_assigned_tasks].flatten
          )
        end
      end

      context "when there are tasks completed by the assignee" do
        let!(:assignee_completed_tasks) do
          create_list(:education_assess_documentation_task, 4, :completed, assigned_to: assignee)
        end

        it "does not return the completed tasks" do
          expect(subject).not_to include(
            [assignee_completed_tasks].flatten
          )
        end
      end
    end
  end
end
