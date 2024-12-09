# frozen_string_literal: true

describe NightlySyncsJob, :all_dbs do
  subject { described_class.perform_now }

  context "when the job runs successfully" do
    before do
      5.times { create(:staff) }

      @emitted_gauges = []
      allow(MetricsService).to receive(:emit_gauge) do |args|
        @emitted_gauges.push(args)
      end
    end

    it "updates cached_user_attributes table" do
      subject

      expect(CachedUser.count).to eq(5)
    end

    it "updates DataDog" do
      subject

      expect(@emitted_gauges).to include(
        app_name: "caseflow_job",
        metric_group: "nightly_syncs_job",
        metric_name: "runtime",
        metric_value: anything
      )
    end

    context "dangling LegacyAppeal" do
      class FakeTask < Dispatch::Task
      end

      context "with zero tasks" do
        let!(:legacy_appeal) { create(:legacy_appeal) }

        it "deletes the legacy appeal and does not include it in slack report" do
          slack_msg = ""
          slack_msg_error_text = "VACOLS cases which cannot be deleted by sync_vacols_cases:"
          allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }
          subject

          expect(slack_msg.include?(slack_msg_error_text)).to be false
          expect { legacy_appeal.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        context "and an open dispatch_task" do
          let!(:dispatch_task) { FakeTask.create(appeal: legacy_appeal, aasm_state: :unassigned) }

          it "cancels all open dispatch_task and leaves the legacy appeal intact" do
            expect(dispatch_task.open?).to eq true
            subject

            expect(legacy_appeal.reload).to_not be_nil
            expect(legacy_appeal.reload.tasks.open).to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).to be_empty
          end
        end
        context "and a closed dispatch_task" do
          let!(:dispatch_task) { FakeTask.create(appeal: legacy_appeal, aasm_state: :completed, user: nil) }

          it "leaves the legacy appeal intact" do
            expect(dispatch_task.open?).to eq false
            subject

            expect(legacy_appeal.reload).to_not be_nil
            expect(legacy_appeal.reload.tasks.open).to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).to be_empty
          end
        end
      end

      context "with open tasks" do
        let!(:legacy_appeal) { create(:legacy_appeal, :with_judge_assign_task) }

        it "cancels all open tasks and leaves the legacy appeal intact" do
          subject

          expect(legacy_appeal.reload).to_not be_nil
          expect(legacy_appeal.reload.tasks.open).to be_empty
        end

        context "and open dispatch_task" do
          let!(:dispatch_task) { FakeTask.create(appeal: legacy_appeal, aasm_state: :unassigned) }

          it "cancels all open *tasks and leaves the legacy appeal intact" do
            expect(legacy_appeal.reload.tasks.open).not_to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).not_to be_empty
            subject

            expect(legacy_appeal.reload).to_not be_nil
            expect(legacy_appeal.reload.tasks.open).to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).to be_empty
          end
        end
        context "and closed dispatch_task" do
          let!(:dispatch_task) { FakeTask.create(appeal: legacy_appeal, aasm_state: :completed, user: nil) }

          it "cancels all open tasks and leaves the legacy appeal intact" do
            expect(legacy_appeal.reload.tasks.open).not_to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).to be_empty
            subject

            expect(legacy_appeal.reload).to_not be_nil
            expect(legacy_appeal.reload.tasks.open).to be_empty
            expect(legacy_appeal.reload.dispatch_tasks.open).to be_empty
          end
        end
      end

      context "with open hearing tasks" do
        let!(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks) }

        it "cancels all open tasks and leaves the legacy appeal intact without throwing an error" do
          subject

          expect(legacy_appeal.reload).to_not be_nil
          expect(legacy_appeal.reload.tasks.open).to be_empty
        end
      end
    end

    context "open DecisionReviewTasks" do
      let(:education) { create(:business_line, url: "education") }
      let(:veteran) { create(:veteran) }
      let(:hlr) do
        create(:higher_level_review, benefit_type: "education", veteran_file_number: veteran.file_number)
      end
      let!(:request_issue) { create(:request_issue, :removed, decision_review: hlr) }
      let!(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: education) }
      let!(:board_grant_effectuation_task) do
        create(:board_grant_effectuation_task, appeal: hlr, assigned_to: education)
      end

      it "cancels any for completed cases" do
        expect(task.reload).to be_assigned

        subject

        expect(task.reload).to be_cancelled
        expect(board_grant_effectuation_task.reload).to be_assigned
      end
    end

    # our BGSService fake returns five records in the poas_list, this creates one of the records
    # before the job and verifies that the job creates the remaining four records
    context "with BGS attorneys" do
      before { create(:bgs_attorney, participant_id: "12345678") }

      it "creates new attorney records if they do not exist" do
        subject

        expect(BgsAttorney.count).to eq 5
      end
    end

    context "#sync_hearing_states" do
      let(:pending_hearing_appeal_state) do
        create_appeal_state_with_case_record_and_hearing(nil)
      end

      let(:postponed_hearing_appeal_state) do
        create_appeal_state_with_case_record_and_hearing("P")
      end

      let(:withdrawn_hearing_appeal_state) do
        create_appeal_state_with_case_record_and_hearing("C")
      end

      let(:scheduled_in_error_hearing_appeal_state) do
        create_appeal_state_with_case_record_and_hearing("E")
      end

      let(:held_hearing_appeal_state) do
        create_appeal_state_with_case_record_and_hearing("H")
      end

      it "Job synchronizes hearing statuses" do
        expect([pending_hearing_appeal_state,
                postponed_hearing_appeal_state,
                withdrawn_hearing_appeal_state,
                scheduled_in_error_hearing_appeal_state,
                held_hearing_appeal_state].all?(&:hearing_scheduled)).to eq true

        subject

        expect(pending_hearing_appeal_state.hearing_scheduled).to eq true

        expect(postponed_hearing_appeal_state.reload.hearing_scheduled).to eq false
        expect(postponed_hearing_appeal_state.hearing_postponed).to eq true

        expect(withdrawn_hearing_appeal_state.reload.hearing_scheduled).to eq false
        expect(withdrawn_hearing_appeal_state.hearing_withdrawn).to eq true

        expect(scheduled_in_error_hearing_appeal_state.reload.hearing_scheduled).to eq false
        expect(scheduled_in_error_hearing_appeal_state.scheduled_in_error).to eq true

        expect(held_hearing_appeal_state.reload.hearing_scheduled).to eq false
      end

      it "catches standard errors" do
        expect([pending_hearing_appeal_state,
                postponed_hearing_appeal_state,
                withdrawn_hearing_appeal_state,
                scheduled_in_error_hearing_appeal_state,
                held_hearing_appeal_state].all?(&:hearing_scheduled)).to eq true

        allow(AppealState).to receive(:where).and_raise(StandardError)
        slack_msg = ""
        slack_msg_error_text = "Fatal error in sync_hearing_states"
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        subject

        expect(slack_msg.include?(slack_msg_error_text)).to be true
      end

      # Hearing scheduled will be set to true to simulate Caseflow missing a
      # disposition update.
      def create_appeal_state_with_case_record_and_hearing(desired_disposition)
        case_hearing = create(:case_hearing, hearing_disp: desired_disposition)
        vacols_case = create(:case, case_hearings: [case_hearing])
        appeal = create(:legacy_appeal, vacols_case: vacols_case)

        appeal.appeal_state.tap { _1.update!(hearing_scheduled: true) }
      end
    end
  end

  context "#sync_decided_appeals" do
    let(:decided_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(true, true)
    end

    let(:undecided_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(false, true)
    end

    let(:missing_vacols_case_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(true, false)
    end

    it "Job syncs decided appeals decision_mailed status", bypass_cleaner: true do
      expect([decided_appeal_state,
              undecided_appeal_state,
              missing_vacols_case_appeal_state].all?(&:decision_mailed)).to eq false

      subject

      expect(decided_appeal_state.reload.decision_mailed).to eq true
      expect(undecided_appeal_state.reload.decision_mailed).to eq false
      expect(missing_vacols_case_appeal_state.reload.decision_mailed).to eq false
    end

    it "catches standard errors", bypass_cleaner: true do
      expect([decided_appeal_state,
              undecided_appeal_state,
              missing_vacols_case_appeal_state].all?(&:decision_mailed)).to eq false

      allow(AppealState).to receive(:legacy).and_raise(StandardError)
      slack_msg = ""
      slack_msg_error_text = "Fatal error in sync_decided_appeals"
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      subject

      expect(slack_msg.include?(slack_msg_error_text)).to be true
    end

    # Clean up parallel threads
    after(:each) { clean_up_after_threads }

    # VACOLS record's decision date will be set to simulate a decided appeal
    # decision_mailed will be set to false for the AppealState to verify the method
    # functionality
    def create_decided_appeal_state_with_case_record_and_hearing(decided_appeal, create_case)
      case_hearing = create(:case_hearing)
      decision_date = decided_appeal ? Time.current : nil
      vacols_case = create_case ? create(:case, case_hearings: [case_hearing], bfddec: decision_date) : nil
      appeal = create(:legacy_appeal, vacols_case: vacols_case)

      appeal.appeal_state.tap { _1.update!(decision_mailed: false) }
    end

    def clean_up_after_threads
      DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
    end
  end

  context "when errors occur" do
    context "in the sync_vacols_cases step" do
      context "due to existing FK associations" do
        let!(:legacy_appeal) { create(:legacy_appeal) }
        let!(:legacy_hearing) { create(:legacy_hearing, appeal: legacy_appeal) }
        let!(:snapshot) { AppealStreamSnapshot.create!(appeal: legacy_appeal, hearing: legacy_hearing) }

        it "handles the error and doesn't delete record" do
          slack_msg = ""
          expected_slack_msg = "VACOLS cases which cannot be deleted by sync_vacols_cases:"
          allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }
          allow(Raven).to receive(:capture_exception)
          subject

          expect(legacy_appeal.reload).to_not be_nil
          expect(Raven).to have_received(:capture_exception)
            .with(anything, extra: { legacy_appeal_id: legacy_appeal.id })
          expect(slack_msg.include?(expected_slack_msg)).to be true
          # BgsAttorney.count verifies that the rest of the job ran as expected based on our service fake
          expect(BgsAttorney.count).to eq 5
        end
      end
    end

    context "in any step due to miscellaneous errors" do
      it "skips step and continues job" do
        # raises error during sync_vacols_users step
        allow(CachedUser).to receive(:sync_from_vacols).and_raise(StandardError)

        # raises error during sync_vacols_cases step
        allow_any_instance_of(LegacyAppealsWithNoVacolsCase).to receive(:call).and_raise(StandardError)

        # raises error during sync_decision_review_tasks
        allow_any_instance_of(DecisionReviewTasksForInactiveAppealsChecker).to receive(:call).and_raise(StandardError)

        # raises error during sync_bgs_attorneys
        allow(BgsAttorney).to receive(:sync_bgs_attorneys).and_raise(StandardError)

        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }
        subject

        # one result for each of the four steps in the job
        expect(slack_msg.split("StandardError").count).to eq 4
      end
    end
  end
end
