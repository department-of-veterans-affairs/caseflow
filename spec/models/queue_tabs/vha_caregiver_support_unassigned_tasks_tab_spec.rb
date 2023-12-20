# frozen_string_literal: true

describe VhaCaregiverSupportUnassignedTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportUnassignedTasksTab.new(params) }
  let(:params) { { assignee: assignee } }
  let(:assignee) { VhaCaregiverSupport.singleton }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaCaregiverSupportUnassignedTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(9)
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    context "when tab label is visible" do
      it "should match defined label for unassigned tasks" do
        is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
      end
    end
  end

  describe ".description" do
    subject { tab.description }

    context "when we want to show the user the description" do
      it "matches description for unassigned tasks tab" do
        is_expected.to eq("Cases assigned to VHA Caregiver Support Program:")
      end
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    context "when the tab name is visible" do
      it "matches expected tab name" do
        is_expected.to eq(Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_UNASSIGNED_TASK_TAB_NAME)
        is_expected.to eq("vha_caregiver_support_unassigned")
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
        is_expected.to match_array assignee_assigned_task
        expect(subject.empty?).not_to eq true
      end
    end
  end
end
