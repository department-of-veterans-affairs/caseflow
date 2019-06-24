# frozen_string_literal: true

describe TaskPage do
  describe ".new" do
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    subject { TaskPage.new(arguments) }

    context "when object is created with no arguments" do
      let(:arguments) { {} }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a nil assignee" do
      let(:assignee) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a valid assignee but no tab name" do
      let(:assignee) { FactoryBot.create(:organization) }
      let(:tab_name) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a valid assignee and a tab name" do
      let(:assignee) { FactoryBot.create(:organization) }

      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe ".tasks_for_tab" do
    let(:assignee) { FactoryBot.create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    subject { TaskPage.new(arguments).tasks_for_tab }

    context "when the tab name is not recognized" do
      let(:tab_name) { "some unknown tab name" }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidTaskTableTab)
      end
    end

    context "when there are some tasks for the given tab name" do
      let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
      let(:task_count) { TaskPage::TASKS_PER_PAGE + 3 }

      before { FactoryBot.create_list(:generic_task, task_count, assigned_to: assignee) }

      it "returns the correct number of tasks" do
        expect(subject.count).to eq(task_count)
      end
    end
  end

  describe ".paged_tasks" do
    let(:assignee) { FactoryBot.create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:page) { 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, page: page } }

    before { FactoryBot.create_list(:generic_task, TaskPage::TASKS_PER_PAGE + 1, assigned_to: assignee) }

    subject { TaskPage.new(arguments).paged_tasks }

    context "when the first page of tasks is requested" do
      it "returns a full page of tasks" do
        expect(subject.count).to eq(TaskPage::TASKS_PER_PAGE)
      end
    end

    context "when the page argument is nil" do
      let(:page) { nil }

      it "returns the first page of tasks" do
        expect(subject.count).to eq(TaskPage::TASKS_PER_PAGE)
      end
    end

    context "when the second page of tasks is requested" do
      let(:page) { 2 }

      it "returns a single task" do
        expect(subject.count).to eq(1)
      end
    end
  end
end
