# frozen_string_literal: true

describe VhaProgramOfficeCompletedTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeCompletedTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks completed to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_closed_tasks) { create_list(:assess_documentation_task, 4, :completed, assigned_to: assignee) }
      let!(:assignee_active_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 3, :on_hold, assigned_to: assignee) }

      it "returns on_hold tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [assignee_closed_tasks].flatten
        )

        expect(subject).not_to include(
          [assignee_active_tasks].flatten
        )

        expect(subject).not_to include(
          [other_folks_tasks].flatten
        )
      end
    end
  end
end
