# frozen_string_literal: true

describe VhaCaregiverSupportCompletedTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_caregiver_support) }

  describe ".label" do
    subject { tab.label }

    context "the tab label should be appropriately reflected" do
      it "matches what is in the Copy.json file" do
        expect(subject).to eq(COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE)
      end
    end
  end

  describe ".description" do
    subject { tab.description }

    context "the description should be appropriately reflected" do
      it "matches what is in the Copy.json file" do
        expect(subject).to eq(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION)
      end
    end
  end

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaCaregiverSupportCompletedTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks completed by the assignee" do
      let!(:assignee_completed_tasks) do
        create_list(:vha_document_search_task, 4, :completed, assigned_to: assignee)
      end

      it "returns Completed tasks" do
        expect(subject).to match_array assignee_completed_tasks
        expect(subject.empty?).not_to eq true
      end

      it "does not return a completed task that is older than a week" do
        assignee_completed_tasks.first.update!(closed_at: (Time.zone.now - (1.week + 1.minute)))
        expect(subject).to_not include assignee_completed_tasks.first
        expect(subject).to match_array assignee_completed_tasks[1..-1]
      end
    end

    context "when the tasks are currently assigned to the assignee" do
      let!(:assignee_assigned_tasks) do
        create_list(:vha_document_search_task, 4, :assigned, assigned_to: assignee)
      end

      it "does not return Assigned tasks" do
        expect(subject).not_to match_array assignee_assigned_tasks
        expect(subject.empty?).to eq true
      end
    end

    context "when the tasks have been cancelled" do
      let!(:assignee_cancelled_tasks) do
        create_list(:vha_document_search_task, 4, :cancelled, assigned_to: assignee)
      end

      it "does not return Cancelled tasks" do
        expect(subject).not_to match_array assignee_cancelled_tasks
        expect(subject.empty?).to eq true
      end
    end

    context "when the tasks are  in On Hold status" do
      let!(:assignee_on_hold_tasks) do
        create_list(:vha_document_search_task, 4, :on_hold, assigned_to: assignee)
      end

      it "does not return On Hold tasks" do
        expect(subject).not_to match_array assignee_on_hold_tasks
        expect(subject.empty?).to eq true
      end
    end

    context "when the tasks are in progress" do
      let!(:assignee_in_progress_tasks) do
        create_list(:vha_document_search_task, 4, :in_progress, assigned_to: assignee)
      end

      it "does not return In Progress tasks" do
        expect(subject).not_to match_array assignee_in_progress_tasks
        expect(subject.empty?).to eq true
      end
    end
  end
end
