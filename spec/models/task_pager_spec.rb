# frozen_string_literal: true

require "faker"

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

      before { create_list(:ama_task, task_count, assigned_to: assignee) }

      it "returns the correct number of tasks" do
        expect(subject.count).to eq(task_count)
      end
    end
  end

  describe ".paged_tasks" do
    let(:assignee) { create(:organization) }
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
    end
  end

  describe ".total_task_count" do
    let(:assignee) { create(:organization) }
    let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
    let(:task_count) { TaskPager::TASKS_PER_PAGE + 1 }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, page: page } }

    before { create_list(:ama_task, task_count, assigned_to: assignee) }

    subject { TaskPager.new(arguments).total_task_count }

    context "when the first page of tasks is requested" do
      let(:page) { 1 }

      it "returns the total task count" do
        expect(subject).to eq(task_count)
      end
    end

    context "when the page argument is nil" do
      let(:page) { nil }

      it "returns the total task count" do
        expect(subject).to eq(task_count)
      end
    end

    context "when the second page of tasks is requested" do
      let(:page) { 2 }

      it "returns the total task count" do
        expect(subject).to eq(task_count)
      end
    end
  end

  describe ".sorted_tasks" do
    let(:task_pager) { TaskPager.new(arguments) }
    let(:arguments) { { assignee: assignee, tab_name: tab_name, sort_by: sort_by, sort_order: sort_order } }
    let(:sort_by) { nil }
    let(:sort_order) { nil }
    let(:assignee) { create(:organization) }
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

        it "sorts tasks in reserve by closed_at value" do
          expected_order = created_tasks.sort_by(&:closed_at).reverse
          expect(subject.map(&:id)).to eq(expected_order.map(&:id))
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

      before do
        regional_offices = RegionalOffice::ROS
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
      let(:sort_by) { Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name }
      let!(:created_tasks) { [] }

      let(:legacy_appeal_1) { create(:legacy_appeal, vacols_case: create(:case, :type_original)) }
      let(:legacy_appeal_2) { create(:legacy_appeal, vacols_case: create(:case, :type_post_remand)) }
      let(:legacy_appeal_3) { create(:legacy_appeal, vacols_case: create(:case, :type_cavc_remand)) }
      let(:appeal_1) { create(:appeal, :advanced_on_docket_due_to_motion) }
      let(:appeal_2) { create(:appeal) }

      before do
        legacy_appeals = [legacy_appeal_1, legacy_appeal_2, legacy_appeal_3]
        legacy_appeals.map do |appeal|
          create(:colocated_task, assigned_to: assignee, appeal: appeal)
          create(:cached_appeal,
                 appeal_id: appeal.id,
                 appeal_type: LegacyAppeal.name,
                 case_type: appeal.type)
        end
        appeals = [appeal_1, appeal_2]
        appeals.map do |appeal|
          create(:ama_colocated_task, assigned_to: assignee, appeal: appeal)
          create(:cached_appeal,
                 appeal_id: appeal.id,
                 appeal_type: Appeal.name,
                 case_type: appeal.type,
                 is_aod: appeal.aod)
        end
      end

      it "sorts by AOD status, case type, and docket number" do
        expected_order = CachedAppeal.all.sort_by do |cached_appeal|
          [cached_appeal.is_aod ? 1 : 0, cached_appeal.case_type, cached_appeal.docket_number]
        end
        expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
      end
    end
  end

  describe ".filtered_tasks" do
    let(:assignee) { create(:organization) }
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
