# frozen_string_literal: true

describe QueueColumn, :all_dbs do
  describe ".from_name" do
    subject { QueueColumn.from_name(column_name) }

    context "when the column name is null" do
      let(:column_name) { nil }

      it "return nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when the column name matches a column defined in the queue config" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name }

      it "return an instance of QueueColumn" do
        expect(subject).to be_a(QueueColumn)

        expect(subject.filterable).to eq(true)
        expect(subject.name).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name)
        expect(subject.sorting_table).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_table)
        expect(subject.sorting_columns).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_columns)
      end
    end
  end

  describe ".format_option_label" do
    subject { QueueColumn.format_option_label(label, count) }

    let(:count) { rand(100) }

    context "when label is null" do
      let(:label) { nil }

      it "returns the special blank value" do
        expect(subject).to eq("#{COPY::NULL_FILTER_LABEL} (#{count})")
      end
    end

    context "when label is a string with some length" do
      let(:label) { Generators::Random.word_characters(rand(1..20)) }

      it "returns the properly formatted option label" do
        expect(subject).to eq("#{label} (#{count})")
      end
    end
  end

  describe ".filter_option_hash" do
    subject { QueueColumn.filter_option_hash(value, label) }

    let(:label) { Generators::Random.word_characters(rand(1..20)) }

    def match_encoding(str)
      URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape(str))
    end

    context "when input value is null" do
      let(:value) { nil }

      it "changes the null value to the special blank field value" do
        expect(subject[:value]).to eq(match_encoding(COPY::NULL_FILTER_LABEL))
      end

      it "does not alter the input label" do
        expect(subject[:displayText]).to eq(label)
      end
    end

    context "when input value is a string that contains special characters" do
      let(:value) { "Winston-Salem, N.Car." }

      it "properly encodes the value" do
        expect(subject[:value]).to eq(match_encoding(value))
      end
    end
  end

  describe ".filter_options" do
    subject { QueueColumn.from_name(column_name).filter_options(tasks) }

    context "when the column is not filterable" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name }
      let(:tasks) { create_list(:task, 5) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MustImplementInSubclass)
      end
    end

    context "for the case type column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name }
      let(:tasks) { Task.where(id: create_list(:task, 5).map(&:id)) }
      let(:aod_count) { 3 }

      before do
        tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal.class.name,
            appeal_id: task.appeal.id,
            is_aod: (index < aod_count),
            case_type: VACOLS::Case::TYPES[(index + 1).to_s]
          )
        end
      end

      it "returns an array that includes AOD option" do
        option = QueueColumn.filter_option_hash(
          Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key,
          QueueColumn.format_option_label("AOD", aod_count)
        )
        expect(subject).to include(option)
      end

      it "returns an array with all present case types" do
        (1..5).each do |index|
          type_name = VACOLS::Case::TYPES[index.to_s]
          option = QueueColumn.filter_option_hash(type_name, QueueColumn.format_option_label(type_name, 1))

          expect(subject).to include(option)
        end
      end
    end

    context "for the docket type column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name }
      let(:docket_types) { Constants::DOCKET_NAME_FILTERS.keys }
      let(:tasks_per_type) { 2 }
      let(:tasks) { Task.where(id: create_list(:task, (docket_types.length * tasks_per_type)).map(&:id)) }

      before do
        tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal.class.name,
            appeal_id: task.appeal.id,
            docket_type: docket_types[index % docket_types.length]
          )
        end
      end

      it "returns an array with all present case types" do
        docket_types.each do |docket_type|
          type_name = Constants::DOCKET_NAME_FILTERS[docket_type]
          label = QueueColumn.format_option_label(type_name, tasks_per_type)
          option = QueueColumn.filter_option_hash(docket_type, label)

          expect(subject).to include(option)
        end
      end
    end

    context "for the regional office column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name }
      let(:regional_office_cities_sample) do
        Constants::REGIONAL_OFFICE_INFORMATION.keys.sample(12).map do |ro_key|
          Constants::REGIONAL_OFFICE_INFORMATION[ro_key]["city"]
        end.uniq
      end
      let(:tasks_per_ro) { 3 }
      let(:tasks) do
        Task.where(id: create_list(:task, (regional_office_cities_sample.length * tasks_per_ro)).map(&:id))
      end

      before do
        tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal.class.name,
            appeal_id: task.appeal.id,
            closest_regional_office_city: regional_office_cities_sample[index % regional_office_cities_sample.length]
          )
        end
      end

      it "returns an array with all present regional office cities" do
        regional_office_cities_sample.each do |city|
          option = QueueColumn.filter_option_hash(city, QueueColumn.format_option_label(city, tasks_per_ro))

          expect(subject).to include(option)
        end
      end
    end

    context "for the task type column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name }
      let(:root_tasks) { RootTask.where(id: create_list(:root_task, 3).map(&:id)) }
      let(:distribution_tasks) { DistributionTask.where(id: create_list(:distribution_task, 4).map(&:id)) }
      let(:foia_tasks) { FoiaTask.where(id: create_list(:foia_task, 5).map(&:id)) }
      let(:tasks) { Task.where(id: root_tasks.map(&:id) + distribution_tasks.map(&:id) + foia_tasks.map(&:id)) }

      it "returns an array with all present task types" do
        [root_tasks, distribution_tasks, foia_tasks].each do |task_set|
          task_type = task_set.first.type
          task_label = task_set.first.label
          label = QueueColumn.format_option_label(task_label, task_set.count)
          option = QueueColumn.filter_option_hash(task_type, label)

          expect(subject).to include(option)
        end
      end
    end

    context "for the assignee column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name }
      let(:orgs) { create_list(:organization, 2) }
      let(:users) { create_list(:user, 2) }
      let(:org_1_tasks) { Task.where(id: create_list(:task, 1, assigned_to: orgs.first).map(&:id)) }
      let(:org_2_tasks) { Task.where(id: create_list(:task, 2, assigned_to: orgs.second).map(&:id)) }
      let(:user_1_tasks) { Task.where(id: create_list(:task, 3, assigned_to: users.first).map(&:id)) }
      let(:user_2_tasks) { Task.where(id: create_list(:task, 4, assigned_to: users.second).map(&:id)) }
      let(:tasks) do
        Task.where(id: org_1_tasks.map(&:id) + org_2_tasks.map(&:id) + user_1_tasks.map(&:id) + user_2_tasks.map(&:id))
      end

      it "returns an array with all present user names" do
        [org_1_tasks, org_2_tasks, user_1_tasks, user_2_tasks].each do |task_set|
          assignee = task_set.first.assigned_to
          name = assignee.is_a?(Organization) ? assignee.name : assignee.css_id
          option = QueueColumn.filter_option_hash(name, QueueColumn.format_option_label(name, task_set.count))

          expect(subject).to include(option)
        end
      end
    end

    context "for the issue types column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name }
      let(:org) { create(:organization) }
      let(:org_tasks) { create_list(:root_task, 5, assigned_to: org) }
      let(:tasks) { Task.where(id: org_tasks.pluck(:id)) }
      let(:issue_categories) do
        [
          "Other",
          "Beneficiary Travel",
          "CHAMPVA",
          "Spina Bifida Treatment (Non-Compensation)",
          "Beneficiary Travel"
        ]
      end
      let(:request_issues) do
        issue_categories.map do |issue_category|
          create(:request_issue, nonrating_issue_category: issue_category)
        end
      end

      before do
        org_tasks.each_with_index do |task, index|
          task.appeal.request_issues << request_issues[index]
          task.save
          task.appeal.save
        end

        # Setup cached appeals
        org_tasks.each do |task|
          create(
            :cached_appeal,
            appeal_type: task.appeal.class.name,
            appeal_id: task.appeal.id,
            issue_types: task.appeal.request_issues.map(&:nonrating_issue_category).uniq.sort_by(&:upcase).join(",")
          )
        end
      end

      it "returns an array with all the issue_categories" do
        issue_types_filter = org_tasks.map { |task| task.appeal.request_issues.map(&:nonrating_issue_category).uniq }
          .flatten
          .group_by { |item| item }
          .transform_values(&:count)

        issue_types_filter.each do |issue_type, count|
          option = QueueColumn.filter_option_hash(issue_type, QueueColumn.format_option_label(issue_type, count))
          expect(subject).to include(option)
        end
      end

      context "for the Vha Camo Org" do
        let(:org) { VhaCamo.singleton }

        it "returns an array with all the task issue_categories and all possible issue categories" do
          issue_types_filter = org_tasks.map { |task| task.appeal.request_issues.map(&:nonrating_issue_category).uniq }
            .flatten
            .group_by { |item| item }
            .transform_values(&:count)

          issue_types_filter.each do |issue_type, count|
            option = QueueColumn.filter_option_hash(issue_type, QueueColumn.format_option_label(issue_type, count))
            expect(subject).to include(option)
          end

          # There should be 12 total possible issue categories for VhaCamo
          expect(subject.count).to eq 12
        end
      end
    end
  end
end
