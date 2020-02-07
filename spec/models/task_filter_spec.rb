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

      it "instantiates with given arguments" do
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

        it "returns only translation tasks assigned to the current organization" do
          expect(subject.map(&:id)).to_not match_array(all_tasks.map(&:id))
          expect(subject.map(&:type).uniq).to eq([TranslationTask.name])
          expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id))
        end
      end

      context "when filter includes TranslationTasks and FoiaTasks" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name},#{FoiaTask.name}"]
        end

        it "returns all translation and FOIA tasks assigned to the current organization" do
          expect(subject.map(&:type).uniq).to match_array([TranslationTask.name, FoiaTask.name])
          expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id) + foia_tasks.map(&:id))
        end
      end
    end

    context "when filtering by regional office" do
      let(:tasks_per_city) { 3 }
      let(:regional_office_cities) do
        RegionalOffice::ROS.sort.take(5).map { |ro_key| RegionalOffice::CITIES[ro_key][:city] }
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

      before do
        all_tasks.each_with_index do |task, idx|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            closest_regional_office_city: regional_office_cities[idx / tasks_per_city % regional_office_cities.length]
          )
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
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name}&val=Boston,Washington"]
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
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name}&val=#{docket_types[0]},#{docket_types[2]}"]
        end

        it "returns tasks with direct review dockets or hearing dockets" do
          expect(subject.map(&:id)).to match_array(review_tasks.map(&:id) + hearing_tasks.map(&:id))
        end
      end
    end

    context "when filtering by case type" do
      let(:tasks_per_type) { 3 }
      let(:case_types) { VACOLS::Case::TYPES }
      let(:type_1_tasks) { create_list(:task, tasks_per_type) }
      let(:type_2_tasks) { create_list(:task, tasks_per_type) }
      let(:type_3_tasks) { create_list(:task, tasks_per_type) }
      let(:type_4_tasks) { create_list(:task, tasks_per_type) }
      let(:type_5_tasks) { create_list(:task, tasks_per_type) }
      let(:all_tasks) do
        Task.where(id: (type_1_tasks + type_2_tasks + type_3_tasks + type_4_tasks + type_5_tasks).map(&:id).sort)
      end

      before do
        all_tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            is_aod: (index % tasks_per_type == 0),
            case_type: case_types[(index / tasks_per_type + 1).to_s]
          )
        end
      end

      let(:aod_case_ids) do
        [
          type_1_tasks.first.id,
          type_2_tasks.first.id,
          type_3_tasks.first.id,
          type_4_tasks.first.id,
          type_5_tasks.first.id
        ]
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
          expect(subject.map(&:id)).to match_array(type_1_tasks.map(&:id))
        end
      end

      context "when filter includes Original and Supplemental" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=#{case_types['1']},#{case_types['2']}"]
        end

        it "returns tasks with Original or Supplemental case types", skip: "flakey" do
          expect(subject.map(&:id)).to match_array(type_1_tasks.map(&:id) + type_2_tasks.map(&:id))
        end
      end

      context "when filter includes Original and Supplemental and AOD" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name}&val=#{case_types['1']},#{case_types['2']},is_aod"]
        end

        it "returns tasks with Original or Supplemental case types or AOD cases" do
          expect(subject.map(&:id)).to match_array((type_1_tasks.map(&:id) + type_2_tasks.map(&:id)) | aod_case_ids)
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

      before do
        all_tasks.each do |task|
          create(
            :cached_appeal,
            appeal_type: task.appeal_type,
            appeal_id: task.appeal.id,
            assignee_label: task.appeal.assigned_to_location
          )
        end
      end

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
        let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name}&val=#{users.first.css_id}"] }

        it "returns only tasks where the closest regional office is Boston" do
          expect(subject.map(&:id)).to match_array(first_user_tasks.map(&:id))
        end
      end

      context "when filter includes Boston and Washington" do
        let(:filter_params) do
          ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name}&val=#{users.first.css_id},#{users.second.css_id}"]
        end

        it "returns tasks where the closest regional office is Boston or Washington" do
          expect(subject.map(&:id)).to match_array((first_user_tasks + second_user_tasks).map(&:id))
        end
      end
    end
  end
end
