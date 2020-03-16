# frozen_string_literal: true

describe TaskSorter, :all_dbs do
  describe ".new" do
    subject { TaskSorter.new(args) }

    context "with no input arguments" do
      let(:args) { {} }

      it "instantiates with default arguments" do
        expect { subject }.to_not raise_error

        expect(subject.column.name).to eq(Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name)
        expect(subject.sort_order).to eq(Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC)
        expect(subject.tasks).to eq([])
      end
    end

    context "with an invalid sort order" do
      let(:args) { { sort_order: "bad_sort_order" } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when the input column is just a column name" do
      let(:args) { { column: Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when the input tasks argument is not an ActiveRecord::Relation object" do
      let(:args) { { tasks: [create(:ama_task)] } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when all input arguments are valid" do
      let(:column) { QueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name) }
      let(:sort_order) { Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC }
      let(:tasks) { Task.where(id: create_list(:ama_task, 6).pluck(:id)) }

      let(:args) { { column: column, sort_order: sort_order, tasks: tasks } }

      it "instantiates with given arguments" do
        expect { subject }.to_not raise_error

        expect(subject.column).to eq(column)
        expect(subject.sort_order).to eq(sort_order)
        expect(subject.tasks).to eq(tasks)
      end
    end
  end

  describe ".sorted_tasks" do
    subject { TaskSorter.new(args).sorted_tasks }

    context "when there are no tasks" do
      let(:args) { {} }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when there are tasks and we specify a column to sort by" do
      let(:tasks) { Task.where(id: create_list(:ama_task, 14).pluck(:id)) }
      let(:args) { { tasks: tasks, column: QueueColumn.from_name(column_name) } }

      context "when sorting by closed_at date" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name }

        before do
          tasks.each do |task|
            # Update each task to be closed some time in the past 6 days so they're included in recently closed tasks.
            task.update!(status: Constants.TASK_STATUSES.completed, closed_at: rand(6 * 24 * 60).minutes.ago)
          end
        end

        it "sorts tasks by closed_at value" do
          expect(subject.pluck(:id)).to eq(tasks.order(:closed_at).pluck(:id))
        end
      end

      context "when sorting by days waiting" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name }

        before do
          tasks.each do |task|
            # Update each task to be assigned some time in the past 30 days.
            task.update!(assigned_at: rand(30 * 24 * 60).minutes.ago)
          end
        end

        it "sorts tasks by assigned_at value" do
          expect(subject.pluck(:id)).to eq(tasks.order(:assigned_at).pluck(:id))
        end
      end

      context "when sorting by due date" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_DUE_DATE.name }

        before do
          tasks.each do |task|
            # Update each task to be assigned some time in the past 30 days.
            task.update!(assigned_at: rand(30 * 24 * 60).minutes.ago)
          end
        end

        it "sorts tasks by assigned_at value" do
          expect(subject.pluck(:id)).to eq(tasks.order(:assigned_at).pluck(:id))
        end
      end

      context "when sorting by assigner" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name }

        before do
          tasks.each do |task|
            # Update each task to be assigned some random user
            task.update!(
              assigned_by: create(:user, full_name: "#{Faker::Name.unique.first_name} #{Faker::Name.unique.first_name}")
            )
          end
        end

        it "sorts tasks by assigned_by last name" do
          expected_order = tasks.sort_by { |task| task.assigned_by_display_name.last }
          expect(subject.pluck(:id)).to eq(expected_order.pluck(:id))
        end
      end

      context "when sorting by task type" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name }
        let(:tasks) { Task.where(id: create_list(:ama_task, task_types.length).pluck(:id)) }

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
          Colocated.singleton.add_user(create(:user))
          tasks.each_with_index { |task, index| task.update!(type: task_types[index].name) }
        end

        it "sorts ColocatedTasks by label" do
          expect(subject.map(&:label)).to eq(tasks.reload.sort_by(&:label).map(&:label))
        end
      end

      context "when sorting by days on hold" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_HOLD_LENGTH.name }

        before do
          tasks.each do |task|
            # Update each task to be place on hold at some time in the past 30 days.
            task.update!(placed_on_hold_at: rand(30 * 24 * 60).minutes.ago)
          end
        end

        it "sorts tasks by placed_on_hold_at value" do
          expect(subject.pluck(:id)).to eq(tasks.order(:placed_on_hold_at).pluck(:id))
        end
      end

      context "when sorting by docket number column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name }

        before do
          tasks.each do |task|
            create(:cached_appeal, appeal_id: task.appeal_id, appeal_type: task.appeal_type)
          end
        end

        it "sorts using ascending order by default" do
          expect(subject.pluck(:appeal_id)).to eq(CachedAppeal.order(:docket_type, :docket_number).pluck(:appeal_id))
        end
      end

      context "when sorting by closest regional office column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name }

        before do
          regional_offices = RegionalOffice::ROS
            .uniq { |ro_key| RegionalOffice::CITIES[ro_key][:city] }
            .shuffle
          tasks.each_with_index do |task, index|
            ro_key = regional_offices[index]
            ro_city = RegionalOffice::CITIES[ro_key][:city]
            task.appeal.update!(closest_regional_office: ro_key)
            create(:cached_appeal, appeal_id: task.appeal_id, closest_regional_office_city: ro_city)
          end
        end

        it "sorts by regional office city" do
          expect(subject.pluck(:appeal_id)).to eq(CachedAppeal.order(:closest_regional_office_city).pluck(:appeal_id))
        end
      end

      context "when sorting by issue count column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name }

        before do
          issue_counts = (0..tasks.length).to_a.shuffle
          tasks.each_with_index do |task, index|
            appeal = create(:appeal, request_issues: build_list(:request_issue, issue_counts[index]))
            task.update!(appeal_id: appeal.id)
            create(:cached_appeal, appeal_id: task.appeal_id, issue_count: issue_counts[index])
          end
        end

        it "sorts by issue count" do
          expected_order = tasks.sort_by { |task| task.appeal.issues[:request_issues].count }
          expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
        end
      end

      context "when sorting by assigned to column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name }
        let(:tasks) { Task.where(id: create_list(:ama_task, 5).pluck(:id)) }

        before do
          users = []
          5.times do
            users.push(create(:user, css_id: Faker::Name.unique.first_name))
          end
          tasks.each_with_index do |task, index|
            user = users[index % 5]
            task.update!(assigned_to_id: user.id)
            create(:cached_appeal, appeal_id: task.appeal_id, assignee_label: user.css_id)
          end
        end

        it "sorts by assigned to" do
          expected_order = tasks.sort_by { |task| task.appeal.assigned_to_location }
          expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
        end
      end

      context "when sorting by case details link column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name }

        before do
          tasks.each do |task|
            first_name = Faker::Name.first_name
            last_name = "#{Faker::Name.middle_name} #{Faker::Name.last_name}"
            task.appeal.veteran.update!(first_name: first_name, last_name: last_name)
            create(
              :cached_appeal,
              appeal_id: task.appeal_id,
              veteran_name: "#{last_name.split(' ').last}, #{first_name.split(' ').first}"
            )
          end
        end

        it "sorts by veteran last and first name" do
          expected_order = tasks.sort_by do |task|
            last_name = task.appeal.veteran_last_name.split(" ").last.upcase
            first_name = task.appeal.veteran_first_name.split(" ").first.upcase
            "#{last_name}, #{first_name}"
          end
          expect(subject.map(&:appeal_id)).to eq(expected_order.map(&:appeal_id))
        end
      end

      context "when sorting by Appeal Type column" do
        let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name }
        let(:tasks) { Task.where(assigned_to: org) }

        let(:org) { create(:organization) }

        before do
          Colocated.singleton.add_user(create(:user))

          vacols_case_types = [:type_original, :type_post_remand, :type_cavc_remand]
          vacols_case_types.each do |case_type|
            appeal = create(:legacy_appeal, vacols_case: create(:case, case_type))
            create(:colocated_task, appeal: appeal, assigned_to: org)
            create(:cached_appeal,
                   appeal_id: appeal.id,
                   appeal_type: LegacyAppeal.name,
                   case_type: appeal.type)
          end

          appeals = [create(:appeal, :advanced_on_docket_due_to_motion), create(:appeal)]
          appeals.each do |appeal|
            create(:ama_colocated_task, appeal: appeal, assigned_to: org)
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
  end
end
