# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe TaskPager, :all_dbs do
  describe ".new" do
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    subject { TaskPager.new(arguments) }

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
      let(:assignee) { create(:organization) }
      let(:tab_name) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when sort order is invalid" do
      let(:assignee) { create(:organization) }
      let(:arguments) { { assignee: assignee, tab_name: tab_name, sort_order: "invalid" } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a valid assignee and a tab name" do
      let(:assignee) { create(:organization) }

      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe ".tasks_for_tab" do
    let(:assignee) { create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    subject { TaskPager.new(arguments).tasks_for_tab }

    context "when the tab name is not recognized" do
      let(:tab_name) { "some unknown tab name" }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidTaskTableTab)
      end
    end

    context "when there are some tasks for the given tab name" do
      let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
      let(:task_count) { TaskPager::TASKS_PER_PAGE + 3 }

      before { create_list(:generic_task, task_count, assigned_to: assignee) }

      it "returns the correct number of tasks" do
        expect(subject.count).to eq(task_count)
      end
    end
  end

  describe ".paged_tasks" do
    let(:assignee) { create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:page) { 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, page: page } }

    before { create_list(:generic_task, TaskPager::TASKS_PER_PAGE + 1, assigned_to: assignee) }

    subject { TaskPager.new(arguments).paged_tasks }

    context "when the first page of tasks is requested" do
      it "returns a full page of tasks" do
        expect(subject.count).to eq(TaskPager::TASKS_PER_PAGE)
      end
    end

    context "when the page argument is nil" do
      let(:page) { nil }

      it "returns the first page of tasks" do
        expect(subject.count).to eq(TaskPager::TASKS_PER_PAGE)
      end
    end

    context "when the second page of tasks is requested" do
      let(:page) { 2 }

      it "returns a single task" do
        expect(subject.count).to eq(1)
      end
    end
  end

  describe ".sorted_tasks" do
    let(:task_pager) { TaskPager.new(arguments) }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, sort_by: sort_by } }
    let(:sort_by) { nil }
    let(:assignee) { create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:tasks) { task_pager.tasks_for_tab }

    let!(:created_tasks) { create_list(:generic_task, 14, assigned_to: assignee) }

    subject { task_pager.sorted_tasks(tasks) }

    context "when no sorting arguments are provided to TaskPager" do
      let(:arguments) { { assignee: assignee, tab_name: tab_name } }

      it "sorts tasks by created_at asc" do
        expected_order = created_tasks.sort_by(&:created_at)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when desc sort_order argument is provided to TaskPager" do
      let(:arguments) do
        { assignee: assignee, tab_name: tab_name, sort_order: Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC }
      end

      it "sorts tasks by created_at desc" do
        expected_order = created_tasks.sort_by(&:created_at).reverse
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by closed_at date" do
      let(:sort_by) { Constants.QUEUE_CONFIG.TASK_CLOSED_DATE_COLUMN }
      let(:tab_name) { Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME }

      before do
        created_tasks.each do |task|
          # Update each task to be closed some time in the past 6 days so that it is included in recently closed tasks.
          task.update!(status: Constants.TASK_STATUSES.completed, closed_at: rand(6 * 24 * 60).minutes.ago)
        end
      end

      it "sorts tasks by closed_at value" do
        expected_order = created_tasks.sort_by(&:closed_at)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by days waiting" do
      let(:sort_by) { Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN }

      before do
        created_tasks.each do |task|
          # Update each task to be assigned some time in the past 30 days.
          task.update!(assigned_at: rand(30 * 24 * 60).minutes.ago)
        end
      end

      it "sorts tasks by assigned_at value" do
        expected_order = created_tasks.sort_by(&:assigned_at)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by due date" do
      let(:sort_by) { Constants.QUEUE_CONFIG.TASK_DUE_DATE_COLUMN }

      before do
        created_tasks.each do |task|
          # Update each task to be assigned some time in the past 30 days.
          task.update!(assigned_at: rand(30 * 24 * 60).minutes.ago)
        end
      end

      it "sorts tasks by assigned_at value" do
        expected_order = created_tasks.sort_by(&:assigned_at)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by task type" do
      let(:sort_by) { Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN }
      let!(:created_tasks) { create_list(:colocated_task, 14, assigned_to: assignee) }

      it "sorts ColocatedTasks by action and created_at" do
        expected_order = created_tasks.sort_by { |task| [task.action, task.created_at] }
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by days on hold" do
      let(:sort_by) { Constants.QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN }

      before do
        created_tasks.each do |task|
          # Update each task to be place on hold at some time in the past 30 days.
          task.update!(placed_on_hold_at: rand(30 * 24 * 60).minutes.ago)
        end
      end

      it "sorts tasks by placed_on_hold_at value" do
        expected_order = created_tasks.sort_by(&:placed_on_hold_at)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by docket number column" do
      let(:sort_by) { Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN }

      before do
        created_tasks.each do |task|
          create(:cached_appeal, appeal_id: task.appeal_id, appeal_type: task.appeal_type)
        end
      end

      it "sorts using ascending order by default" do
        expected_order = CachedAppeal.all.sort_by(&:docket_number)
        expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
      end
    end
  end

  describe ".filtered_tasks" do
    let(:assignee) { create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:filters) { [] }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, filters: filters } }

    let(:task_pager) { TaskPager.new(arguments) }
    subject { task_pager.filtered_tasks }

    context "when there are a variety of task assigned to the current organization" do
      let!(:privacy_act_tasks) { create_list(:privacy_act_task, 3, assigned_to: assignee) }
      let!(:foia_tasks) { create_list(:foia_task, 5, assigned_to: assignee) }
      let!(:track_veteran_tasks) { create_list(:track_veteran_task, 7, assigned_to: assignee) }
      let!(:translation_tasks) { create_list(:translation_task, 11, assigned_to: assignee) }

      context "when filters is an empty array" do
        let(:filters) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(task_pager.tasks_for_tab.map(&:id))
        end
      end

      context "when filter includes TranslationTasks" do
        let(:filters) { ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{TranslationTask.name}"] }

        it "returns only translation tasks assigned to the current organization" do
          expect(subject.map(&:id)).to_not match_array(task_pager.tasks_for_tab.map(&:id))
          expect(subject.map(&:type).uniq).to eq([TranslationTask.name])
          expect(subject.length).to eq(translation_tasks.count)
        end
      end

      context "when filter includes TranslationTasks and FoiaTasks" do
        let(:filters) do
          ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{TranslationTask.name},#{FoiaTask.name}"]
        end

        it "returns all translation and FOIA tasks assigned to the current organization" do
          expect(subject.map(&:type).uniq).to match_array([TranslationTask.name, FoiaTask.name])
          expect(subject.length).to eq(translation_tasks.count + foia_tasks.count)
        end
      end
    end
  end
end
