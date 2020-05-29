# frozen_string_literal: true

describe AssignedTasksTab, :postgres do
  let(:tab) { AssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column,
      type: type
    }
  end
  let(:assignee) { create(:user) }
  let(:show_regional_office_column) { false }
  let(:type) { nil }

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_active_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_judge_assign_tasks) { create_list(:ama_judge_assign_task, 3, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:ama_task, 3, :on_hold, assigned_to: assignee) }

      it "does not return judge assign tasks" do
        expect(subject).to match_array(assignee_active_tasks)
      end

      context "when the assignee is an org" do
        let(:assignee) { create(:organization) }

        it "raises an error" do
          expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
        end
      end
    end
  end
end
