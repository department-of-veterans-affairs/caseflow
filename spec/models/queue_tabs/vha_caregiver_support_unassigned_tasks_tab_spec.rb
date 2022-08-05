# frozen_string_literal: true

describe VhaCaregiverSupportUnassignedTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportUnassignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_reader_link_column: show_reader_link_column
    }
  end
  let(:assignee) { create(:vha_caregiver_support) }
  let(:show_reader_link_column) { false }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaCaregiverSupportUnassignedTasksTab" do
      let(:params) { { assignee: create(:vha_caregiver_support) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
    end

    context "when we want to show the reader link column" do
      let(:show_reader_link_column) { true }
      let(:params) do
        { assignee: create(:vha_caregiver_support),
          show_reader_link_column: show_reader_link_column }
      end

      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
      it "includes the reader link column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name)
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    context "when tab label is visible" do
      it "should match defined label for unassigned tasks" do
        expect(subject).to eq(COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TAB_TITLE)
        expect(subject).to eq("Unassigned")
      end
    end
  end

  describe ".description" do
    subject { tab.description }

    context "when we want to show the user the description" do
      it "matches description for unassigned tasks tab" do
        expect(subject).to eq(COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION)
        expect(subject).to eq("Cases assigned to VHA Caregiver Support Program:")
      end
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    context "when the tab name is visible" do
      it "matches expected tab name" do
        expect(subject).to eq(Constants.QUEUE_CONFIG.VHA_CAREGIVER_SUPPORT_UNASSIGNED_TASK_TAB_NAME)
        expect(subject).to eq("vha_caregiver_support_unassigned")
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when assignee views unassigned tab" do
      let!(:assignee_assigned_task) do
        create_list(:vha_document_search_task, 4, :assigned, assigned_to: assignee)
      end

      it "returns a list of unassigned tasks" do
        expect(subject).to match_array assignee_assigned_task
        expect(subject.empty?).not_to eq true
      end
    end
  end
end
