# frozen_string_literal: true

describe VhaProgramOfficeInProgressTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeInProgressTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeInProgressTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks in progress to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_in_progress_tasks) do
        create_list(:assess_documentation_task, 4, :in_progress, assigned_to: assignee)
      end
      let!(:assignee_assigned_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }

      it "returns in progress tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [assignee_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [assignee_assigned_tasks].flatten
        )

        expect(subject).not_to include(
          [other_folks_tasks].flatten
        )
      end
    end
  end
end
