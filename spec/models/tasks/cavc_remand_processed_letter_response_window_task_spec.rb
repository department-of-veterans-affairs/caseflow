# frozen_string_literal: true

describe CavcRemandProcessedLetterResponseWindowTask, :postgres do
  require_relative "task_shared_examples.rb"
  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let(:other_user) { create(:user) }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let(:appeal) { create(:appeal) }
    let!(:parent_task) { create(:cavc_task, appeal: appeal) }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected defaults" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::CRP_LETTER_RESP_WINDOW_TASK_LABEL
      expect(new_task.default_instructions).to eq [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
    end

    describe ".create_with_hold" do
      subject { described_class.create_with_hold(parent_task) }

      it "creates task with child TimedHoldTask" do
        new_task = subject
        expect(new_task).to be_valid
        expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(new_task.status).to eq Constants.TASK_STATUSES.on_hold

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task
        child_timed_hold_tasks = new_task.children.of_type(:TimedHoldTask)
        expect(child_timed_hold_tasks.count).to eq 1
        expect(child_timed_hold_tasks.first.assigned_to).to eq CavcLitigationSupport.singleton
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned
        expect(child_timed_hold_tasks.first.timer_end_time.to_date).to eq(Time.zone.now.to_date + 90.days)

        expect(new_task.label).to eq COPY::CRP_LETTER_RESP_WINDOW_TASK_LABEL
        expect(new_task.default_instructions).to eq [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
      end
    end
  end

  SendCRPLetterTask = SendCavcRemandProcessedLetterTask
  CRPLRWindowTask = CavcRemandProcessedLetterResponseWindowTask
  describe "#available_actions" do
    shared_examples "has correct actions" do
      context "while window task is on-hold" do
        context "window task assigned to org" do
          it "returns on-hold actions available to org" do
            child_timed_hold_task = window_task.children.of_type(:TimedHoldTask).active.first
            expect(child_timed_hold_task.status).to eq Constants.TASK_STATUSES.assigned

            expect(window_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
            expect(window_task.available_actions(org_admin)).to match_array CRPLRWindowTask::ORG_ACTIONS
            expect(window_task.available_actions(org_nonadmin)).to match_array CRPLRWindowTask::ORG_ACTIONS

            expect(window_task.available_actions(other_user)).to be_empty
          end
        end
        context "window task assigned to CAVC user" do
          let!(:user_window_task) do
            window_task.on_hold!
            CRPLRWindowTask.create_with_hold(window_task, days_on_hold: 80, assignee: org_nonadmin)
          end

          it "returns on-hold actions available to user" do
            child_timed_hold_task = user_window_task.children.of_type(:TimedHoldTask).active.first
            expect(child_timed_hold_task.status).to eq Constants.TASK_STATUSES.assigned

            expect(user_window_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
            expect(user_window_task.available_actions(org_admin)).to match_array CRPLRWindowTask::USER_ACTIONS
            expect(user_window_task.available_actions(org_nonadmin)).to match_array CRPLRWindowTask::USER_ACTIONS

            expect(user_window_task.available_actions(other_user)).to be_empty
          end
        end
      end

      context "after timed-hold window ends (due to cancellation or time passed)" do
        context "window task assigned to org" do
          it "returns actions available to org" do
            child_timed_hold_task = window_task.children.of_type(:TimedHoldTask).active.first
            expect(child_timed_hold_task.status).to eq Constants.TASK_STATUSES.assigned

            Timecop.travel(Time.zone.now + 90.days + 1.hour)
            TaskTimerJob.perform_now
            expect(child_timed_hold_task.reload.status).to eq Constants.TASK_STATUSES.completed

            expect(window_task.reload.status).to eq Constants.TASK_STATUSES.assigned
            expect(window_task.available_actions(org_admin)).to match_array CRPLRWindowTask::ORG_ACTIONS
            expect(window_task.available_actions(org_nonadmin)).to match_array CRPLRWindowTask::ORG_ACTIONS

            expect(window_task.available_actions(other_user)).to be_empty
          end
        end
        context "window task assigned to CAVC user" do
          let!(:user_window_task) do
            window_task.on_hold!
            CRPLRWindowTask.create_with_hold(window_task, days_on_hold: 80, assignee: org_nonadmin)
          end

          it "returns actions available to user" do
            child_timed_hold_task = user_window_task.children.of_type(:TimedHoldTask).active.first
            expect(child_timed_hold_task.status).to eq Constants.TASK_STATUSES.assigned

            Timecop.travel(Time.zone.now + 80.days + 1.hour)
            TaskTimerJob.perform_now
            expect(child_timed_hold_task.reload.status).to eq Constants.TASK_STATUSES.completed

            expect(user_window_task.reload.status).to eq Constants.TASK_STATUSES.assigned

            expected_actions = CRPLRWindowTask::USER_ACTIONS_FOR_ACTIVE_TASK
            expect(user_window_task.available_actions(org_admin)).to match_array expected_actions
            expect(user_window_task.available_actions(org_nonadmin)).to match_array expected_actions

            expect(user_window_task.available_actions(other_user)).to be_empty
          end
        end
      end
    end

    let(:org_task) { create(:send_cavc_remand_processed_letter_task) }
    let(:send_task) { org_task }
    let!(:window_task) do
      send_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin)
      send_task.appeal.tasks.of_type(:CavcRemandProcessedLetterResponseWindowTask).first
    end

    context "window task created after org-assigned SendCRPLetterTask completed" do
      include_examples "has correct actions"
    end

    context "window task created after user-assigned SendCRPLetterTask completed" do
      let(:send_task) { create(:send_cavc_remand_processed_letter_task, parent: org_task, assigned_to: org_nonadmin) }
      include_examples "has correct actions"
    end
  end

  describe "#when_child_task_created" do
    let!(:window_task) do
      send_task = create(:send_cavc_remand_processed_letter_task)
      send_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin)
      send_task.appeal.tasks.of_type(:CavcRemandProcessedLetterResponseWindowTask).first
    end

    subject do
      # simulates "Assign to person", which creates child task
      CavcRemandProcessedLetterResponseWindowTask.create!(parent: window_task,
                                                          appeal: window_task.appeal,
                                                          assigned_to: org_nonadmin)
    end

    context "when assigning task to person" do
      context "open TimedHoldTask child exists" do
        it "has open TimedHoldTask child under newly created child task" do
          timed_hold_task = subject.children.open.of_type(:TimedHoldTask).first
          expect(timed_hold_task.status).to eq "assigned"
        end
      end
      context "no open TimedHoldTask child exists" do
        before do
          timed_hold_task = window_task.children.open.of_type(:TimedHoldTask).first
          timed_hold_task.cancelled!
        end
        it "does not have TimedHoldTask child under newly created child task" do
          timed_hold_task = subject.children.open.of_type(:TimedHoldTask).first
          expect(timed_hold_task).to eq nil
        end
      end
    end
  end
end
