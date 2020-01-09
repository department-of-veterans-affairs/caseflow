# frozen_string_literal: true

describe OrganizationUnassignedTasksTab, :postgres do
  let(:tab) { OrganizationUnassignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column,
      show_reader_link_column: show_reader_link_column,
      allow_bulk_assign: allow_bulk_assign
    }
  end
  let(:assignee) { create(:organization) }
  let(:show_regional_office_column) { false }
  let(:show_reader_link_column) { false }
  let(:allow_bulk_assign) { false }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating the object" do
      let(:params) { { assignee: create(:organization) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(6)
      end

      it "does not include optional columns" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
        expect(subject).to_not include(Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name)
      end
    end

    context "when we want to show the regional office column" do
      let(:show_regional_office_column) { true }

      it "includes the regional office column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
      end
    end

    context "when we want to show the reader link column" do
      let(:show_reader_link_column) { true }

      it "includes the reader link column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name)
      end
    end
  end

  describe ".allow_bulk_assign?" do
    subject { tab.allow_bulk_assign? }

    context "when only the assignee argument is passed when instantiating the object" do
      let(:params) { { assignee: create(:organization) } }

      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when input argument is true" do
      let(:allow_bulk_assign) { true }

      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:ama_task, 11) }
      let!(:assignee_active_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:ama_task, 3, :assigned, assigned_to: assignee) }

      before do
        assignee_on_hold_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.on_hold) }
      end

      it "only returns assignee's active tasks" do
        expect(subject).to match_array(assignee_active_tasks)
      end
    end
  end
end
