# frozen_string_literal: true

describe VhaProgramOfficeOnHoldTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeOnHoldTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeOnHoldTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq 8
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_ON_HOLD_TAB_TITLE
      is_expected.to eq "On Hold (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq "Cases on hold in a #{assignee.name} team member's queue."
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.VHA_PO_ON_HOLD_TASKS_TAB_NAME)
      is_expected.to eq("po_on_hold")
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_active_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 3, :on_hold, assigned_to: assignee) }

      it "returns on_hold tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [assignee_on_hold_tasks].flatten
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
