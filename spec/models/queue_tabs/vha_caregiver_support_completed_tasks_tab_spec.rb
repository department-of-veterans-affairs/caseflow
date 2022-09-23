# frozen_string_literal: true

describe VhaCaregiverSupportCompletedTasksTab, :postgres do
<<<<<<< HEAD
  let(:completed_tab) { VhaCaregiverSupportCompletedTasksTab.new(params) }
=======
  let(:tab) { VhaCaregiverSupportCompletedTasksTab.new(params) }
>>>>>>> fixing_branch
  let(:params) do
    {
      assignee: assignee
    }
  end
<<<<<<< HEAD
  let(:assignee) { VhaCaregiverSupport.singleton }
=======
  let(:assignee) { create(:vha_caregiver_support) }
>>>>>>> fixing_branch

  describe ".tab_name" do
    subject { VhaCaregiverSupportCompletedTasksTab.tab_name }

    context "the tab name should be appropriately reflected" do
      it "matches what is defined in the QUEUE_CONFIG file" do
        expect(subject).to eq(Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_COMPLETED_TASKS_TAB_NAME)
        expect(subject).to eq("caregiver_support_completed")
      end
    end
  end

  describe ".label" do
<<<<<<< HEAD
    subject { completed_tab.label }
=======
    subject { tab.label }
>>>>>>> fixing_branch

    context "the tab label should be appropriately reflected" do
      it "matches what is defined in the Copy.json file" do
        expect(subject).to eq(COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE)
        expect(subject).to eq("Completed")
      end
    end
  end

  describe ".description" do
<<<<<<< HEAD
    subject { completed_tab.description }
=======
    subject { tab.description }
>>>>>>> fixing_branch

    context "the description should be appropriately reflected" do
      it "matches what is defined in the Copy.json file" do
        expect(subject).to eq(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION)
        expect(subject).to eq("Cases completed (last 7 days):")
      end
    end
  end

  describe ".column_names" do
<<<<<<< HEAD
    subject { completed_tab.column_names }
=======
    subject { tab.column_names }
>>>>>>> fixing_branch

    context "when only the assignee argument is passed when instantiating an VhaCaregiverSupportCompletedTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
    end
  end

  describe ".tasks" do
<<<<<<< HEAD
    subject { completed_tab.tasks }
=======
    subject { tab.tasks }
>>>>>>> fixing_branch
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
<<<<<<< HEAD

      it "tasks no longer show up in the completed tab whenever BVA Intake return the appeal to the VHA CSP" do
        expect(completed_tab.tasks).to match_array assignee_completed_tasks

        # Add a more recent VHA CSP task to make sure the older one gets removed from the queue
        targeted_task = assignee_completed_tasks.first
        new_task = VhaDocumentSearchTask.create!(
          appeal: targeted_task.appeal,
          parent: targeted_task.parent,
          assigned_to: assignee
        )

        expect(completed_tab.tasks).to match_array(assignee_completed_tasks - [targeted_task])

        # Newest task appears in completed tab, but the first task that used to be in the completed tab for
        # the appeal is still omitted.
        new_task.completed!
        expect(completed_tab.tasks).to match_array(assignee_completed_tasks + [new_task] - [targeted_task])
      end
=======
>>>>>>> fixing_branch
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
