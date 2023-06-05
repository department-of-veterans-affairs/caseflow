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
        expect(subject.length).to eq 7
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TAB_TITLE
      is_expected.to eq "In Progress (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq "Cases in progress in a #{assignee.name} team member's queue."
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.VHA_PO_IN_PROGRESS_TASKS_TAB_NAME)
      is_expected.to eq("po_inProgressTab")
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
