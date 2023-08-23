# frozen_string_literal: true

describe VhaProgramOfficeReadyForReviewTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeReadyForReviewTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeReadyForReviewTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq 8
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_PAGE_READY_FOR_REVIEW_TAB_TITLE
      is_expected.to eq "Ready for Review (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq "Cases ready for review in a #{assignee.name} team member's queue."
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.READY_FOR_REVIEW_TASKS_TAB_NAME)
      is_expected.to eq("readyForReviewTab")
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee with a completed child AssessDocumentationTask" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_assigned_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_completed_tasks) { create_list(:assess_documentation_task, 4, :completed, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 3, :on_hold, assigned_to: assignee) }
      let!(:parent_assigned_tasks_with_children) do
        assignee_on_hold_tasks.map do |task|
          create(:assess_documentation_task, :completed, assigned_to: create(:vha_regional_office), parent: task)
          task.update!(status: Constants.TASK_STATUSES.assigned)
          task
        end
      end

      it "returns ready for review tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [parent_assigned_tasks_with_children].flatten
        )

        expect(subject).not_to include(
          [assignee_completed_tasks].flatten
        )

        expect(subject).not_to include(
          [other_folks_tasks].flatten
        )
      end
    end
  end
end
