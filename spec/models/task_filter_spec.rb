# frozen_string_literal: true

describe TaskFilter, :all_dbs do
  describe ".new"  do
    let(:args) { { filter_params: filter_params } }

    subject { TaskFilter.new(args) }

    context "when input filter_params argument is nil" do
      let(:filter_params) { nil }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input filter_params argument is a string" do
      let(:filter_params) { "filter_params" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input filter_params argument an empty array" do
      let(:filter_params) { [] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(TaskFilter)
      end
    end

    context "when input filter_params argument an array formatted as expected" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{RootTask.name}"] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(TaskFilter)
      end
    end

    context "when the input tasks argument is not an ActiveRecord::Relation object" do
      let(:args) { { tasks: [create(:ama_task)] } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when all input arguments are valid" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{RootTask.name}"] }
      let(:tasks) { Task.where(id: create_list(:ama_task, 6).pluck(:id)) }

      let(:args) { { filter_params: filter_params, tasks: tasks } }

      it "instantiates with given arguments", :aggregate_failures do
        expect { subject }.to_not raise_error

        expect(subject.filter_params).to eq(filter_params)
        expect(subject.tasks).to eq(tasks)
      end
    end
  end

  describe ".where_clause" do
    subject { TaskFilter.new(filter_params: filter_params).where_clause }

    context "when filter_params is an empty array" do
      let(:filter_params) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when filtering on task type" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{RootTask.name}"] }

      it "returns the expected where_clause" do
        expect(subject).to eq([
                                "tasks.type IN (?)",
                                [RootTask.name]
                              ])
      end
    end

    context "filtering on suggested hearing location" do
      let(:col) { Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME }
      let(:unescaped_val) { "San Francisco, CA(VA)" }
      let(:val) { URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape(unescaped_val)) }
      let(:filter_params) { ["col=#{col}&val=#{val}"] }

      it "calls the QueueFilterParameter#from_string" do
        expect(QueueFilterParameter)
          .to receive(:from_string)
          .once.with(filter_params.first)
          .and_return({})
        subject
      end

      it "returns the expected where_clause" do
        expect(subject).to eq([
                                "cached_appeal_attributes.suggested_hearing_location IN (?)",
                                [unescaped_val]
                              ])
      end
    end

    context "when filtering on issue types" do
      let(:filter_value) { "Other" }
      let(:database_column_name) { "cached_appeal_attributes.issue_types" }
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name}&val=#{filter_value}"] }

      it "when the filter matches a value in the ISSUE_CATEGORIES json it returns the expected where_clause" do
        # expect(subject).to eq(["POSITION('#{filter_value}' IN #{database_column_name}) > 0"])
        expect(subject).to eq(
          [
            "('#{filter_value}' = ANY (string_to_array(#{database_column_name}, ',')) )"
          ]
        )
      end

      context "when the filter value is None" do
        let(:filter_value) { "None" }

        it "returns the expected where_clause" do
          expect(subject).to eq(["(#{database_column_name} IS NULL OR #{database_column_name} = '' )"])
        end
      end

      context "when the filter value does not exist in the defined ISSUE_CATEGORIES json" do
        let(:filter_value) { "Category C" }

        it "returns a falsey placeholder boolean" do
          expect(subject).to eq(["(1=0 )"])
        end
      end
    end
  end

  describe ".filtered_tasks" do
    subject { TaskFilter.new(filter_params: filter_params, tasks: all_tasks).filtered_tasks }

    context "when filtering by task type" do
      let(:foia_tasks) { create_list(:foia_task, 5) }
      let(:translation_tasks) { create_list(:translation_task, 6) }
      let(:ama_tasks) { create_list(:ama_task, 7) }
      let(:all_tasks) do
        Task.where(id: foia_tasks.pluck(:id) + translation_tasks.pluck(:id) + ama_tasks.pluck(:id))
      end

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter includes TranslationTasks" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name}"] }

        it "returns only translation tasks assigned to the current organization", :aggregate_failures do
          expect(subject.map(&:id)).to_not match_array(all_tasks.map(&:id))
          expect(subject.map(&:type).uniq).to eq([TranslationTask.name])
          expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id))
        end
      end

      context "when filter includes TranslationTasks and FoiaTasks" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name}|#{FoiaTask.name}"]
        end

        it "returns all translation and FOIA tasks assigned to the current organization", :aggregate_failures do
          expect(subject.map(&:type).uniq).to match_array([TranslationTask.name, FoiaTask.name])
          expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id) + foia_tasks.map(&:id))
        end
      end
    end

    context "when filtering by regional office" do
      let(:tasks_per_city) { 3 }
      let(:number_of_regional_office_cities) { 5 }
      let(:regional_office_cities) do
        ["Washington", "Digital Service HQ", "Washington", "Boston", "Togus"]
      end
      let(:washington_tasks_1) { create_list(:task, tasks_per_city) }
      let(:ds_tasks) { create_list(:task, tasks_per_city) }
      let(:washington_tasks_2) { create_list(:task, tasks_per_city) }
      let(:boston_tasks) { create_list(:task, tasks_per_city) }
      let(:togus_tasks) { create_list(:task, tasks_per_city) }
      let(:all_tasks) do
        Task.where(id: (washington_tasks_1 + ds_tasks + washington_tasks_2 + boston_tasks + togus_tasks)
          .pluck(:id).sort)
      end

      def create_cached_appeals_per_city(tasks, city)
        tasks.each do |task|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            closest_regional_office_city: city
          )
        end
      end

      before do
        # order of task sets must match order of regional_office_cities
        [washington_tasks_1, ds_tasks, washington_tasks_2, boston_tasks, togus_tasks].each_with_index do |tasks, idx|
          create_cached_appeals_per_city(tasks, regional_office_cities[idx])
        end
      end

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter_params includes a non existent city" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name}&val=Minas Tirith"] }

        it "returns no tasks" do
          expect(subject).to match_array([])
        end
      end

      context "when filter includes Boston" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name}&val=Boston"] }

        it "returns only tasks where the closest regional office is Boston" do
          expect(subject.map(&:id)).to match_array(boston_tasks.map(&:id))
        end
      end

      context "when filter includes Boston and Washington" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name}&val=Boston|Washington"]
        end

        it "returns tasks where the closest regional office is Boston or Washington" do
          expect(subject.map(&:id)).to match_array((boston_tasks + washington_tasks_1 + washington_tasks_2).map(&:id))
        end
      end
    end

    context "when filtering by docket type" do
      let(:tasks_per_type) { 3 }
      let(:docket_types) { Constants::DOCKET_NAME_FILTERS.keys.sort }
      let(:review_tasks) { create_list(:task, tasks_per_type) }
      let(:evidence_tasks) { create_list(:task, tasks_per_type) }
      let(:hearing_tasks) { create_list(:task, tasks_per_type) }
      let(:legacy_tasks) { create_list(:task, tasks_per_type) }
      let(:all_tasks) do
        Task
          .where(id: (review_tasks + evidence_tasks + hearing_tasks + legacy_tasks).pluck(:id).sort)
          .order(id: :asc)
      end

      before do
        all_tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            docket_type: docket_types[index / tasks_per_type % docket_types.length]
          )
        end
      end

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter_params includes a non existent docket type" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name}&val=trial_by_combat"] }

        it "returns no tasks" do
          expect(subject).to match_array([])
        end
      end

      context "when filter includes direct review" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name}&val=#{docket_types[0]}"] }

        it "returns only tasks with direct review dockets" do
          expect(subject.map(&:id)).to match_array(review_tasks.map(&:id))
        end
      end

      context "when filter includes direct review and hearing" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name}&val=#{docket_types[0]}|#{docket_types[2]}"]
        end

        it "returns tasks with direct review dockets or hearing dockets" do
          expect(subject.map(&:id)).to match_array(review_tasks.map(&:id) + hearing_tasks.map(&:id))
        end
      end
    end

    context "when filtering by case type" do
      let(:tasks_per_type) { 3 }
      let(:case_types) { VACOLS::Case::TYPES }
      let(:tasks_type_original) { create_list(:task, tasks_per_type) }
      let(:tasks_type_supplemental) { create_list(:task, tasks_per_type) }
      let(:tasks_type_post_remand) { create_list(:task, tasks_per_type) }
      let(:tasks_type_reconsideration) { create_list(:task, tasks_per_type) }
      let(:tasks_type_vacate) { create_list(:task, tasks_per_type) }
      let(:all_tasks) do
        Task.where(
          id: (
            tasks_type_original +
            tasks_type_supplemental +
            tasks_type_post_remand +
            tasks_type_reconsideration +
            tasks_type_vacate
          ).map(&:id).sort
        )
      end

      def create_cached_appeals_for_tasks(tasks, case_type)
        tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            is_aod: (index % tasks_per_type == 0),
            case_type: case_type
          )
        end
      end

      before do
        create_cached_appeals_for_tasks(tasks_type_original, case_types["1"])
        create_cached_appeals_for_tasks(tasks_type_supplemental, case_types["2"])
        create_cached_appeals_for_tasks(tasks_type_post_remand, case_types["3"])
        create_cached_appeals_for_tasks(tasks_type_reconsideration, case_types["4"])
        create_cached_appeals_for_tasks(tasks_type_vacate, case_types["5"])
      end

      let(:aod_case_ids) do
        all_tasks.select { |task| CachedAppeal.find_by(appeal_id: task.appeal.id).is_aod }.map(&:id)
      end

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter_params includes a non existent case type" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=Invalid"] }

        it "returns no tasks" do
          expect(subject).to match_array([])
        end
      end

      context "when filter includes Original" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=#{case_types['1']}"] }

        it "returns only tasks with Original case types" do
          expect(subject.map(&:id)).to match_array(tasks_type_original.map(&:id))
        end
      end

      context "when filter includes Original and Supplemental" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=#{case_types['1']}|#{case_types['2']}"]
        end

        it "returns tasks with Original or Supplemental case types", skip: "flakey" do
          expect(subject.map(&:id)).to match_array(tasks_type_original.map(&:id) + tasks_type_supplemental.map(&:id))
        end
      end

      context "when filter includes Original and Supplemental and AOD" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=#{case_types['1']}|#{case_types['2']}|is_aod"]
        end

        it "returns tasks with Original or Supplemental case types or AOD cases" do
          expect(subject.map(&:id)).to match_array(
            (tasks_type_original.map(&:id) + tasks_type_supplemental.map(&:id)) | aod_case_ids
          )
        end
      end

      context "when filter includes only AOD" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=is_aod"] }

        it "returns tasks that are AOD" do
          expect(subject.map(&:id)).to match_array(aod_case_ids)
        end
      end
    end

    context "when filtering by assignee" do
      let(:tasks_per_user) { 3 }
      let(:users) { create_list(:user, 3) }
      let(:first_user_tasks) { create_list(:ama_task, tasks_per_user, assigned_to: users.first) }
      let(:second_user_tasks) { create_list(:ama_task, tasks_per_user, assigned_to: users.second) }
      let(:third_user_tasks) { create_list(:ama_task, tasks_per_user, assigned_to: users.third) }
      let(:all_tasks) { Task.where(id: (first_user_tasks + second_user_tasks + third_user_tasks).pluck(:id)) }

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter_params includes a non existent user" do
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name}&val=NON_EXISTANT_USER"] }

        it "returns no tasks" do
          expect(subject).to match_array([])
        end
      end

      context "when filter includes the first user's css_id" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name}&val=#{users.first.css_id}"]
        end

        it "returns only tasks where the closest regional office is Boston" do
          expect(subject.map(&:id)).to match_array(first_user_tasks.map(&:id))
        end
      end

      context "when filter includes the first and second users' css_ids" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name}&"\
            "val=#{users.first.css_id}|#{users.second.css_id}"]
        end

        it "returns tasks assigned to the first and second user" do
          expect(subject.map(&:id)).to match_array((first_user_tasks + second_user_tasks).map(&:id))
        end
      end
    end

    context "filtering by suggested hearing location" do
      let(:winston_salem_key) { "RO18" }
      let(:oakland_key) { "RO43" }
      let(:appeal1) { create(:appeal, closest_regional_office: winston_salem_key) }
      let(:appeal2) { create(:appeal, closest_regional_office: oakland_key) }

      let!(:hearing_location_nyc) do
        create(
          :available_hearing_locations,
          appeal_id: appeal1.id,
          appeal_type: appeal1.class.name,
          city: "New York",
          state: "NY",
          facility_id: "vba_372",
          facility_type: "va_benefits_facility",
          distance: 9
        )
      end

      let!(:hearing_location_sfo) do
        create(
          :available_hearing_locations,
          appeal_id: appeal2.id,
          appeal_type: appeal2.class.name,
          city: "San Francisco",
          state: "CA",
          facility_type: "va_health_facility",
          distance: 100
        )
      end

      let!(:task1) { create(:schedule_hearing_task, appeal: appeal1) }
      let!(:task2) { create(:schedule_hearing_task, appeal: appeal2) }
      let(:all_tasks) { Task.where(id: [task1.id, task2.id]) }

      let(:col) { Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME }
      let(:unescaped_val) { hearing_location_sfo.formatted_location }
      let(:val) { URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape(unescaped_val)) }
      let(:filter_params) { ["col=#{col}&val=#{val}"] }

      it "returns the correct task" do
        UpdateCachedAppealsAttributesJob.new.cache_ama_appeals
        expect(subject.count).to eq 1
        expect(subject.first).to eq task2
      end
    end

    context "when filtering by issue types" do
      let(:all_tasks) { Task.where(id: create_list(:root_task, 6)) }
      let(:issue_categories) do
        [
          "CHAMPVA",
          "Spina Bifida Treatment (Non-Compensation)",
          "Caregiver | Other",
          "Caregiver | Other",
          "Other",
          ""
        ]
      end
      let(:request_issues) do
        issue_categories.map do |issue_category|
          create(:request_issue, nonrating_issue_category: issue_category)
        end
      end
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name }

      before do
        all_tasks.each_with_index do |task, index|
          task.appeal.request_issues << request_issues[index]
          task.save
          task.appeal.save
        end
        UpdateCachedAppealsAttributesJob.new.cache_ama_appeals
      end

      context "when filter_params is an empty array" do
        let(:filter_params) { [] }

        it "returns the same set of tasks for the filtered and unfiltered set" do
          expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
        end
      end

      context "when filter_params includes a non existent issue category" do
        let(:filter_params) { ["col=#{column_name}&val=NON_EXISTANT_ISSUE_CATEGORY"] }

        it "returns no tasks" do
          expect(subject).to match_array([])
        end
      end

      context "when filter_params includes a task without a request issue" do
        let(:filter_params) { ["col=#{column_name}&val=None"] }

        it "returns the task with no request issues" do
          expect(subject).to match_array([all_tasks.last])
        end
      end

      context "when filter_params includes an existing issue category" do
        let(:filter_value) { URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape("Caregiver | Other")) }
        let(:filter_params) { ["col=#{column_name}&val=#{filter_value}"] }

        it "returns the tasks that are associated with an issue_type including 'Caregiver | Other'" do
          expect(subject.map(&:id)).to match_array(all_tasks[2..3].map(&:id))
        end
      end
    end
  end
end
