# frozen_string_literal: true

require "faker"
require_relative "tasks/task_shared_examples.rb"

describe TaskPager, :all_dbs do
  let(:assignee) { create(:organization) }

  before { allow(assignee).to receive(:use_task_pages_api?).and_return(true) unless assignee.nil? }

  describe ".new" do
    shared_examples "missing required property" do
      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    subject { TaskPager.new(arguments) }

    context "when object is created with no arguments" do
      let(:arguments) { {} }

      it_behaves_like "missing required property"
    end

    context "when object is created with a nil assignee" do
      let(:assignee) { nil }

      it_behaves_like "missing required property"
    end

    context "when object is created with a valid assignee but no tab name" do
      let(:tab_name) { nil }

      it_behaves_like "missing required property"
    end

    context "when sort order is invalid" do
      let(:arguments) { { assignee: assignee, tab_name: tab_name, sort_order: "invalid" } }

      it_behaves_like "missing required property"
    end

    context "when object is created with a valid assignee and a tab name" do
      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe ".tasks_for_tab" do
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

      before { create_list(:ama_task, task_count, assigned_to: assignee) }

      it "returns the correct number of tasks" do
        expect(subject.count).to eq(task_count)
      end
    end
  end

  describe ".paged_tasks" do
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:task_count) { TaskPager::TASKS_PER_PAGE + 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, page: page } }

    before { create_list(:ama_task, task_count, assigned_to: assignee) }

    subject { TaskPager.new(arguments).paged_tasks }

    context "when the first page of tasks is requested" do
      let(:page) { 1 }

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

      context "when the assignee is a user" do
        let(:assignee) { create(:user) }
        let(:tab_name) { Constants.QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME }

        it "returns a single task" do
          expect(subject.count).to eq(1)
        end
      end
    end

    context "when pagination is not enabled for the assignee" do
      let(:page) { 1 }
      before { allow(assignee).to receive(:use_task_pages_api?).and_return(false) }

      it "returns all tasks" do
        expect(subject.count).to eq(task_count)
      end
    end

    context "when the tab cannot be paginated" do
      let(:page) { 1 }
      before { allow_any_instance_of(QueueTab).to receive(:contains_legacy_tasks?).and_return(true) }

      it "returns all tasks" do
        expect(subject.count).to eq(task_count)
      end
    end
  end

  describe ".total_task_count" do
    shared_examples "total task count" do
      it "returns the total task count" do
        expect(subject).to eq(task_count)
      end
    end
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:task_count) { TaskPager::TASKS_PER_PAGE + 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, page: page } }

    before { create_list(:ama_task, task_count, assigned_to: assignee) }

    subject { TaskPager.new(arguments).total_task_count }

    context "when the first page of tasks is requested" do
      let(:page) { 1 }

      it_behaves_like "total task count"
    end

    context "when the page argument is nil" do
      let(:page) { nil }

      it_behaves_like "total task count"
    end

    context "when the second page of tasks is requested" do
      let(:page) { 2 }

      it_behaves_like "total task count"
    end

    context "when pagination is not enabled for the assignee" do
      let(:page) { 1 }
      before { allow(assignee).to receive(:use_task_pages_api?).and_return(false) }

      it_behaves_like "total task count"
    end

    context "when the tab cannot be paginated" do
      let(:page) { 1 }
      before { allow_any_instance_of(QueueTab).to receive(:contains_legacy_tasks?).and_return(true) }

      it "returns the total task count" do
        expect(subject).to eq(task_count)
      end
    end
  end

  describe ".task_page_count" do
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:task_count) { TaskPager::TASKS_PER_PAGE + 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name } }

    before { create_list(:ama_task, task_count, assigned_to: assignee) }

    subject { TaskPager.new(arguments).task_page_count }

    context "when pagination is enabled for the assignee" do
      it "returns the total page count" do
        expect(subject).to eq(2)
      end
    end

    context "when pagination is not enabled for the assignee" do
      before { allow(assignee).to receive(:use_task_pages_api?).and_return(false) }

      it "returns one page with all tasks" do
        expect(subject).to eq(1)
      end
    end

    context "when the tab cannot be paginated" do
      let(:page) { 1 }
      before { allow_any_instance_of(QueueTab).to receive(:contains_legacy_tasks?).and_return(true) }

      it "returns one page with all tasks" do
        expect(subject).to eq(1)
      end
    end
  end

  describe ".sorted_tasks" do
    let(:task_pager) { TaskPager.new(arguments) }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, sort_by: sort_by, sort_order: sort_order } }
    let(:sort_by) { nil }
    let(:sort_order) { nil }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:tasks) { task_pager.tasks_for_tab }

    let!(:created_tasks) { create_list(:ama_task, 14, assigned_to: assignee) }

    subject { task_pager.sorted_tasks(tasks) }

    context "when sorting by closed_at date" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name }
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

      context "with desc sort_order" do
        let(:sort_order) { Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC }

        it "sorts tasks in reverse by closed_at value" do
          expected_order = created_tasks.sort_by(&:closed_at).reverse
          expect(subject.map(&:id)).to eq(expected_order.map(&:id))
        end

        context "when the assignee is a user" do
          let(:assignee) { create(:user) }
          let(:tab_name) { Constants.QUEUE_CONFIG.INDIVIDUALLY_COMPLETED_TASKS_TAB_NAME }

          it "sorts tasks in reverse by closed_at value" do
            expected_order = created_tasks.sort_by(&:closed_at).reverse
            expect(subject.map(&:id)).to eq(expected_order.map(&:id))
          end
        end
      end
    end

    context "when sorting by days waiting" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name }

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
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.TASK_DUE_DATE.name }

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
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name }
      let!(:created_tasks) do
        Task.where(id: create_list(:colocated_task, task_types.length, assigned_to: assignee).pluck(:id))
      end

      let(:task_types) do
        [
          AssignHearingDispositionTask,
          AttorneyTask,
          InformalHearingPresentationTask,
          HearingTask,
          ScheduleHearingColocatedTask,
          PreRoutingMissingHearingTranscriptsColocatedTask,
          AttorneyRewriteTask,
          AttorneyDispatchReturnTask,
          AttorneyQualityReviewTask,
          JudgeAssignTask
        ].shuffle
      end

      before do
        created_tasks.each_with_index { |task, index| task.update!(type: task_types[index].name) }
      end

      it "sorts ColocatedTasks by label" do
        expected_order = created_tasks.reload.sort_by(&:label)
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "when sorting by days on hold" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.TASK_HOLD_LENGTH.name }

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
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name }

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

    context "when sorting by closest regional office column" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name }
      let(:virtual_hearing_ro_key) { ["R"] }

      before do
        # Virtual Hearing "RO" has no city, and will never be anyone's
        # closest RO. A nil city breaks this test, but is not a sensible
        # condition to test anyway, so just remove it from the list:
        regional_offices = (RegionalOffice::ROS - virtual_hearing_ro_key)
          .uniq { |ro_key| RegionalOffice::CITIES[ro_key][:city] }
          .shuffle
        created_tasks.each_with_index do |task, index|
          ro_key = regional_offices[index]
          ro_city = RegionalOffice::CITIES[ro_key][:city]
          task.appeal.update!(closest_regional_office: ro_key)
          create(:cached_appeal, appeal_id: task.appeal_id, closest_regional_office_city: ro_city)
        end
      end

      it "sorts by regional office city" do
        expected_order = created_tasks.sort_by do |task|
          RegionalOffice::CITIES[task.appeal.closest_regional_office][:city].upcase.tr(" ", "_")
        end
        expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
      end
    end

    context "when sorting by issue count column" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name }

      before do
        issue_counts = (0..created_tasks.length).to_a.shuffle
        created_tasks.each_with_index do |task, index|
          appeal = create(:appeal, request_issues: build_list(:request_issue, issue_counts[index]))
          task.update!(appeal_id: appeal.id)
          create(:cached_appeal, appeal_id: task.appeal_id, issue_count: issue_counts[index])
        end
      end

      it "sorts by issue count" do
        expected_order = created_tasks.sort_by { |task| task.appeal.issues[:request_issues].count }
        expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
      end
    end

    context "when sorting by case details link column" do
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name }

      before do
        # not random, in order to have deterministic sort for testing.
        first_initials = ("A".."Z").map(&:to_s)
        last_initials = ("Z".."A").map(&:to_s)
        middle_initials = ("a".."z").map(&:to_s)

        created_tasks.each do |task|
          first_name = first_initials.shift
          last_name = "#{middle_initials.shift} #{last_initials.shift}"
          task.appeal.veteran.update!(first_name: first_name, last_name: last_name)
          create(
            :cached_appeal,
            appeal_id: task.appeal_id,
            veteran_name: "#{last_name.split(' ').last}, #{first_name}"
          )
        end
      end

      it "sorts by veteran last and first name" do
        expected_order = created_tasks.sort_by do |task|
          "#{task.appeal.veteran_last_name.split(' ').last}, #{task.appeal.veteran_first_name}"
        end
        expect(subject.map do |task|
          "#{task.appeal.veteran_last_name.split(' ').last}, #{task.appeal.veteran_first_name}"
        end).to eq(expected_order.map do |task|
          "#{task.appeal.veteran_last_name.split(' ').last}, #{task.appeal.veteran_first_name}"
        end)
      end
    end

    context "when sorting by Appeal Type column" do
      let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name }
      let!(:created_tasks) { [] }

      it_behaves_like "sort by Appeal Type column"
    end
  end

  describe ".filtered_tasks" do
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
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
        let(:filters) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name}"] }

        it "returns only translation tasks assigned to the current organization", :aggregate_failures do
          expect(subject.map(&:id)).to_not match_array(task_pager.tasks_for_tab.map(&:id))
          expect(subject.map(&:type).uniq).to eq([TranslationTask.name])
          expect(subject.length).to eq(translation_tasks.count)
        end
      end

      context "when filter includes TranslationTasks and FoiaTasks" do
        let(:filters) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name}|#{FoiaTask.name}"]
        end

        it "returns all translation and FOIA tasks assigned to the current organization", :aggregate_failures do
          expect(subject.map(&:type).uniq).to match_array([TranslationTask.name, FoiaTask.name])
          expect(subject.length).to eq(translation_tasks.count + foia_tasks.count)
        end
      end
    end
  end
end
