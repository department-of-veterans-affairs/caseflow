# frozen_string_literal: true

describe VhaCamoAssignedTasksTab, :postgres do
  let(:tab) { VhaCamoAssignedTasksTab.new(params) }
  let(:params) { { assignee: assignee } }
  let(:assignee) { VhaCamo.singleton }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaCamoAssignedTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
      is_expected.to eq "Assigned (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq "Cases assigned to VHA CAMO:"
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.CAMO_ASSIGNED_TASKS_TAB_NAME)
      is_expected.to eq("camo_assigned")
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when assignee views assigned tab" do
      let!(:assignee_assigned_task) do
        create_list(:vha_document_search_task, 4, :assigned, assigned_to: assignee)
      end

      it "returns a list of assigned tasks" do
        is_expected.to match_array assignee_assigned_task
        expect(subject.empty?).not_to eq true
      end
    end
  end
end
