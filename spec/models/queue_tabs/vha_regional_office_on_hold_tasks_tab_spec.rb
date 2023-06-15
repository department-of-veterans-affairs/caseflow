# frozen_string_literal: true

describe VhaRegionalOfficeOnHoldTasksTab, :postgres do
  let(:tab) { VhaRegionalOfficeOnHoldTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_regional_office) }
  let(:column_name) do
    COLUMN_NAMES = [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
    ].compact
  end
  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaRegionalOfficeOnHoldTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq 9
      end

      it "returns the correct column name" do
        expect(subject).to match_array(column_name)
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it "matches expected tab label" do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_ON_HOLD_TAB_TITLE
      is_expected.to eq "On Hold (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it "contains and matches description provided" do
      is_expected.to_not be nil
      is_expected.to eq "Cases on hold in a #{assignee.name} team member's queue."
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.VHA_PO_ON_HOLD_TASKS_TAB_NAME)
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are task status are on hold" do
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 4, :on_hold, assigned_to: assignee) }
      it "Number of task with assigned status should match the number of task present in tab" do
        expect(assignee_on_hold_tasks.count { |task| task.status = "on_hold" }).to be tab.tasks.length
      end

      it "returns a list of assigned tasks" do
        is_expected.to match_array assignee_on_hold_tasks
        expect(subject.empty?).not_to eq true
      end
    end
  end
end
