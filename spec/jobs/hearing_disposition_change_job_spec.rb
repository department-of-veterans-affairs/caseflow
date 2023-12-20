# frozen_string_literal: true

describe HearingDispositionChangeJob, :all_dbs do
  def create_disposition_task_ancestry(disposition: nil, scheduled_for: nil, associated_hearing: true)
    appeal = create(:appeal)
    root_task = create(:root_task, appeal: appeal)
    distribution_task = create(:distribution_task, parent: root_task)
    parent_hearing_task = create(:hearing_task, parent: distribution_task)

    hearing = create(:hearing, appeal: appeal, disposition: disposition)
    if scheduled_for
      hearing = create(
        :hearing,
        appeal: appeal,
        disposition: disposition,
        scheduled_time: scheduled_for
      )
      hearing_day = create(:hearing_day, scheduled_for: scheduled_for)
      hearing.update!(hearing_day: hearing_day)
    end

    if associated_hearing
      create(:hearing_task_association, hearing: hearing, hearing_task: parent_hearing_task)
    end

    create(:assign_hearing_disposition_task, parent: parent_hearing_task)
  end

  def create_disposition_task_for_legacy_hearings_ancestry(associated_hearing: nil)
    appeal = create(:legacy_appeal, vacols_case: create(:case))
    root_task = create(:root_task, appeal: appeal)
    distribution_task = create(:distribution_task, parent: root_task)
    parent_hearing_task = create(:hearing_task, parent: distribution_task)

    hearing_args = { appeal: appeal }
    hearing_args[:case_hearing] = associated_hearing if associated_hearing
    hearing = create(:legacy_hearing, hearing_args)

    create(:hearing_task_association, hearing: hearing, hearing_task: parent_hearing_task)
    create(:assign_hearing_disposition_task, parent: parent_hearing_task)
  end

  describe ".lock_hearing_days" do
    subject { HearingDispositionChangeJob.new.lock_hearing_days }

    let!(:user) { create(:user) }

    let!(:lockable_hearing_day_ids) do
      [
        create(:hearing_day, scheduled_for: 30.days.ago),
        create(:hearing_day, scheduled_for: 2.days.ago)
      ].pluck(:id)
    end

    let!(:not_lockable_hearing_day_ids) do
      [
        create(:hearing_day, scheduled_for: 1.day.ago),
        create(:hearing_day, scheduled_for: Time.zone.now),
        create(:hearing_day, scheduled_for: 5.days.from_now)
      ].pluck(:id)
    end

    it "locks hearing days from 1 day or longer ago" do
      subject

      expect(HearingDay.where(id: lockable_hearing_day_ids).all?(&:lock)).to eq true
      expect(HearingDay.where(id: not_lockable_hearing_day_ids).any?(&:lock)).to eq false
    end
  end

  describe ".assign_hearing_disposition_task" do
    subject { HearingDispositionChangeJob.new.hearing_disposition_tasks }

    # Property: Class that subclasses DispositionTask.
    context "when there are ChangeHearingDispositionTasks" do
      let!(:disposition_tasks) do
        Array.new(6) { create(:assign_hearing_disposition_task, parent: create(:hearing_task)) }
      end
      let!(:change_disposition_tasks) do
        Array.new(3) { create(:change_hearing_disposition_task, parent: create(:hearing_task)) }
      end

      it "only returns the AssignHearingDispositionTasks" do
        # Confirm that the ChangeHearingDispositionTasks are in the database.
        expect(ChangeHearingDispositionTask.active.count).to(
          eq(change_disposition_tasks.length)
        )

        tasks = subject

        expect(tasks.length).to eq(disposition_tasks.length)
        expect(tasks.pluck(:type).uniq).to eq([AssignHearingDispositionTask.name])
      end
    end
  end

  describe ".update_task_by_hearing_disposition" do
    let(:attributes_date_fields) { %w[assigned_at created_at updated_at] }
    subject { HearingDispositionChangeJob.new.update_task_by_hearing_disposition(task) }

    context "when hearing has a disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: disposition) }

      context "when disposition is held" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.held }
        it "returns a label matching the hearing disposition and call AssignHearingDispositionTask.hold!" do
          expect(task).to receive(:hold!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is cancelled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }
        it "returns a label matching the hearing disposition and call AssignHearingDispositionTask.cancel!" do
          expect(task).to receive(:cancel!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is postponed" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
        it "returns a label matching the hearing disposition and call AssignHearingDispositionTask.postpone!" do
          expect(task).to receive(:postpone!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is no_show" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }
        it "returns a label matching the hearing disposition and call AssignHearingDispositionTask.no_show!" do
          expect(task).to receive(:no_show!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when the disposition is not an expected disposition" do
        let(:disposition) { "FAKE_DISPOSITION" }
        it "returns a label indicating that the hearing disposition is unknown and not change the task" do
          attributes_before = task.attributes.except(*attributes_date_fields)
          expect(subject).to eq(:unknown_disposition)
          expect(task.reload.attributes.except(*attributes_date_fields)).to eq(attributes_before)
        end
      end
    end

    context "when hearing has no disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: nil, scheduled_for: scheduled_for) }

      context "when hearing was scheduled to take place more than 2 days ago" do
        let(:scheduled_for) { 3.days.ago }

        it "returns a label indicating that the hearing is stale, completes the task, and creates a new task" do
          expect(ChangeHearingDispositionTask.count).to eq 0

          expect(subject).to eq(:stale)

          expect(task.reload.closed_at).to_not be_nil
          expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
          expect(ChangeHearingDispositionTask.count).to eq 1
          expect(ChangeHearingDispositionTask.first.appeal).to eq task.appeal
          expect(ChangeHearingDispositionTask.first.parent).to eq task.parent
        end
      end

      context "when hearing was scheduled to take place less than 2 days ago" do
        let(:scheduled_for) { 25.hours.ago }

        it "returns a label indicating that the hearing was recently held and does not change the task" do
          attributes_before = task.attributes.except(*attributes_date_fields)
          expect(subject).to eq(:between_one_and_two_days_old)
          expect(task.reload.attributes.except(*attributes_date_fields)).to eq(attributes_before)
        end
      end
    end

    context "when hearing is a LegacyHearing" do
      let!(:task) { create_disposition_task_for_legacy_hearings_ancestry(associated_hearing: hearing) }

      context "when disposition is held" do
        let(:hearing) { create(:case_hearing, :disposition_held) }
        let(:label) { Constants.HEARING_DISPOSITION_TYPES.held }
        it "returns a label matching the hearing disposition and call AssignHearingDispositionTask.hold!" do
          expect(task).to receive(:hold!).exactly(1).times
          expect(subject).to eq(label)
        end
      end

      context "when hearing does not have a disposition" do
        let(:hearing) { create(:case_hearing) }
        let(:label) { :between_one_and_two_days_old }
        it "returns a label indicating that the hearing has no disposition" do
          expect(subject).to eq(label)
        end
      end
    end
  end

  describe ".log_info" do
    let(:start_time) { 5.minutes.ago }
    let(:task_count_for) { {} }
    let(:error_count) { 0 }
    let(:hearing_ids) { [] }
    let(:error) { nil }

    context "when the job runs successfully" do
      it "logs and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(2).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when there is are elements in the input task_count_for hash" do
      let(:task_count_for) { { first_key: 0, second_key: 13 } }

      it "includes a sentence in the output message for each element of the hash" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Processed 0 First key hearings." \
          " Processed 13 Second key hearings." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when the job encounters a fatal error" do
      let(:err_msg) { "Example error text" }
      # Throw and then catch the error so it has a stack trace.
      let(:error) do
        fail StandardError, err_msg
      rescue StandardError => error
        error
      end

      it "logs an error message and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(3).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob failed after running for .*." \
          " Encountered errors for #{error_count} hearings. Fatal error: #{err_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end

  describe ".perform" do
    subject { HearingDispositionChangeJob.new.perform }

    context "when there is an error outside of the loop" do
      let(:error_msg) { "FAKE ERROR MESSAGE HERE" }

      before do
        expect_any_instance_of(HearingDispositionChangeJob).to receive(:hearing_disposition_tasks).and_raise(error_msg)
      end

      it "sends the correct number of arguments to log_info" do
        args = Array.new(5, anything)
        expect_any_instance_of(HearingDispositionChangeJob).to receive(:log_info).with(*args).exactly(1).times
        subject
      end
    end

    context "when the job runs successfully" do
      let(:not_ready_for_action_count) { 4 }
      let(:error_count) { 13 }
      let(:task_count_for_dispositions) do
        {
          Constants.HEARING_DISPOSITION_TYPES.held.to_sym => 8,
          Constants.HEARING_DISPOSITION_TYPES.cancelled.to_sym => 2,
          Constants.HEARING_DISPOSITION_TYPES.postponed.to_sym => 3,
          Constants.HEARING_DISPOSITION_TYPES.no_show.to_sym => 5,
          Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error.to_sym => 0
        }
      end
      let(:task_count_for_others) do
        {
          between_one_and_two_days_old: 6,
          stale: 7,
          unknown_disposition: 1
        }
      end
      let(:task_count_for) { task_count_for_dispositions.merge(task_count_for_others) }

      before do
        not_ready_for_action_count.times do
          create_disposition_task_ancestry(
            disposition: Constants.HEARING_DISPOSITION_TYPES.held,
            scheduled_for: nil,
            associated_hearing: false
          )
        end

        ready_for_action_time = 36.hours.ago
        task_count_for_dispositions.each do |disposition, task_count|
          task_count.times do
            create_disposition_task_ancestry(
              disposition: disposition,
              scheduled_for: ready_for_action_time,
              associated_hearing: true
            )
          end
        end

        task_count_for_others[:between_one_and_two_days_old].times do
          create_disposition_task_ancestry(
            disposition: nil,
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          )
        end

        task_count_for_others[:stale].times do
          create_disposition_task_ancestry(
            disposition: nil,
            scheduled_for: 5.days.ago,
            associated_hearing: true
          )
        end

        task_count_for_others[:unknown_disposition].times do
          create_disposition_task_ancestry(
            disposition: "FAKE_DISPOSITION",
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          )
        end

        hearing_ids_to_error = Array.new(error_count) do
          create_disposition_task_ancestry(
            disposition: Constants.HEARING_DISPOSITION_TYPES.held,
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          ).hearing.id
        end

        disposition_for_hearing = Hearing.all.map { |hearing| [hearing.id, hearing.disposition] }.to_h

        allow_any_instance_of(Hearing).to receive(:disposition) do |hearing|
          fail "FAKE ERROR MESSAGE" if hearing_ids_to_error.include?(hearing.id)

          disposition_for_hearing[hearing.id]
        end
      end

      it "sends the correct arguments to log_info" do
        expect_any_instance_of(HearingDispositionChangeJob).to(
          receive(:log_info).with(anything, task_count_for, error_count, anything).exactly(1).times
        )
        subject
      end
    end

    context "when we encounter a task related to a legacy hearing that has been deleted from VACOLS" do
      let(:held_hearings_count) { 14 }
      let(:error_count) { 2 }
      let(:task_count_for) do
        {
          Constants.HEARING_DISPOSITION_TYPES.held.to_sym => held_hearings_count,
          Constants.HEARING_DISPOSITION_TYPES.cancelled.to_sym => 0,
          Constants.HEARING_DISPOSITION_TYPES.postponed.to_sym => 0,
          Constants.HEARING_DISPOSITION_TYPES.no_show.to_sym => 0,
          Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error.to_sym => 0,
          between_one_and_two_days_old: 0,
          stale: 0,
          unknown_disposition: 0
        }
      end

      before do
        ready_for_action_time = 36.hours.ago
        held_hearings_count.times do
          create_disposition_task_ancestry(
            disposition: Constants.HEARING_DISPOSITION_TYPES.held.to_sym,
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          )
        end

        error_count.times do
          disposition_task = create_disposition_task_for_legacy_hearings_ancestry

          # Remove the hearing from the VACOLS database so we fail when we try to access a VACOLS field for the hearing.
          VACOLS::CaseHearing.load_hearing(disposition_task.hearing.vacols_id).destroy
        end
      end

      it "runs successfully and notes that there was an error" do
        expect_any_instance_of(HearingDispositionChangeJob).to(
          receive(:log_info).with(anything, task_count_for, error_count, anything).exactly(1).times
        )
        subject
      end
    end

    context "when there are no AssignHearingDispositionTask to be processed" do
      it "runs successfully but does not do any work" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
