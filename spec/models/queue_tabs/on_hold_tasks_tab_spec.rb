# frozen_string_literal: true

describe OnHoldTasksTab, :postgres do
  let(:tab) { OnHoldTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee) { create(:user) }
  let(:show_regional_office_column) { false }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an OnHoldTasksTab" do
      let(:params) { { assignee: assignee } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end

      it "does not include regional office column" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
      end
    end

    context "when we want to show the regional office column" do
      let(:show_regional_office_column) { true }

      it "includes the regional office column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      before { Colocated.singleton.add_user(create(:user)) }

      let!(:other_folks_tasks) { create_list(:ama_task, 1) }
      let!(:assignee_active_tasks) { create_list(:ama_task, 1, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:ama_task, 3, :on_hold, assigned_to: assignee) }
      let!(:assignee_legacy_colocated_tasks) { create_list(:colocated_task, 5, assigned_by: assignee) }
      let!(:other_legacy_colocated_tasks) { create_list(:colocated_task, 1) }
      let!(:assignee_ama_colocated_tasks) do
        create_list(:ama_colocated_task, 1, assigned_by: assignee, appeal: create(:appeal))
      end

      it "returns on hold tasks and legacy colocated tasks the user created" do
        expect(subject).to match_array(
          [assignee_legacy_colocated_tasks, assignee_on_hold_tasks].flatten
        )
      end
    end
  end
end
