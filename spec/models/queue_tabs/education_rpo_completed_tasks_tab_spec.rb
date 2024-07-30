# frozen_string_literal: true

describe EducationRpoCompletedTasksTab, :postgres do
  let(:tab) { EducationRpoCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_rpo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationRpoCompletedTasksTab" do
      let(:params) { { assignee: create(:education_rpo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(5)
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
      is_expected.to eq "Completed"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq COPY::QUEUE_PAGE_COMPLETE_LAST_SEVEN_DAYS_TASKS_DESCRIPTION
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.EDUCATION_RPO_COMPLETED_TASKS_TAB_NAME)
      is_expected.to eq("education_rpo_completed")
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks completed by the assignee" do
      let!(:assignee_completed_tasks) do
        create_list(:education_assess_documentation_task, 4, :completed, assigned_to: assignee)
      end
      let!(:assignee_assigned_tasks) do
        create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee)
      end

      it "returns completed tasks" do
        expect(subject.to_a.difference(assignee_completed_tasks).any?).to eq false
      end

      it "does not return tasks that are not completed" do
        expect(subject.to_a.difference(assignee_assigned_tasks).any?).to eq true
      end
    end

    context "when the tasks are currenlty assigned to the assignee" do
      let!(:assignee_assigned_tasks) do
        create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee)
      end

      it "does not return assigned tasks" do
        expect(subject.empty?).to eq true
      end
    end

    context "when there are tasks in progress by the assignee" do
      let!(:assignee_in_progress_tasks) do
        create_list(:education_assess_documentation_task, 4, :in_progress, assigned_to: assignee)
      end

      it "does not return in progress tasks" do
        expect(subject.empty?).to eq true
      end
    end

    context "when a completed task is older than a week" do
      let!(:assignee_completed_tasks) do
        create_list(:education_assess_documentation_task, 4, :completed, assigned_to: assignee)
      end

      it "does not return older tasks" do
        assignee_completed_tasks.first.update!(closed_at: (Time.zone.now - 2.weeks))
        expect(subject).to_not include assignee_completed_tasks.first
      end
    end
  end
end
