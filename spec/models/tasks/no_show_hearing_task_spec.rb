# frozen_string_literal: true

describe NoShowHearingTask, :postgres do
  let(:appeal) { create(:appeal, :hearing_docket) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:hearing_task) { create(:hearing_task, parent: distribution_task) }
  let!(:disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task) }
  let(:no_show_hearing_task) { create(:no_show_hearing_task, parent: disposition_task) }
  let!(:completed_scheduling_task) do
    create(:schedule_hearing_task, :completed, parent: hearing_task)
  end

  context "create a new NoShowHearingTask" do
    let(:task_params) { { appeal: appeal, parent: disposition_task } }

    subject { NoShowHearingTask.create!(**task_params) }

    it "is assigned to the HearingsManagement org by default" do
      expect(subject.assigned_to_type).to eq "Organization"
      expect(subject.assigned_to).to eq HearingsManagement.singleton
    end

    context "there is a hearings management org user" do
      let!(:hearings_management_user) { create(:hearings_coordinator) }

      before do
        HearingsManagement.singleton.add_user(hearings_management_user)
      end

      it "has actions available to the hearings managment org member" do
        expect(subject.available_actions_unwrapper(hearings_management_user).count).to be > 0
      end
    end

    context "there is a hearing admin org user" do
      let(:hearing_admin_user) { create(:user, station_id: 101) }

      before do
        HearingAdmin.singleton.add_user(hearing_admin_user)
      end

      it "has one action available to the hearing admin user" do
        expect(subject.available_actions_unwrapper(hearing_admin_user).count).to eq 1
      end
    end
  end

  context "create a new NoShowHearingTask with hold" do
    shared_examples "creates task and timed hold task" do
      subject { NoShowHearingTask.create_with_hold(disposition_task) }

      it "creates NoShowHearingTask and TimedHoldTask as child", :aggregate_failures do
        subject

        timed_hold_task = TimedHoldTask.first
        task_timer = timed_hold_task.task_timers.first

        expect(subject.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(timed_hold_task.parent).to eq(subject)
        expect(task_timer.task).to eq(timed_hold_task)
      end
    end

    shared_examples "closes NoShowHearingtask" do
      before { NoShowHearingTask.create_with_hold(disposition_task) }

      subject do
        task_timer = TimedHoldTask.first.task_timers.first
        TaskTimerJob.new.send(:process, task_timer)
      end

      it "closes task and routes correctly", :aggregate_failures do
        subject

        expect(NoShowHearingTask.first.status).to eq(Constants.TASK_STATUSES.completed)
        expect(TimedHoldTask.first.status).to eq(Constants.TASK_STATUSES.completed)

        if appeal.is_a? Appeal
          evidence_task = appeal.tasks.find_by(type: EvidenceSubmissionWindowTask.name)
          expect(evidence_task&.status).to eq(Constants.TASK_STATUSES.assigned)
        else
          expect(appeal.reload.location_code).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
        end
      end
    end

    context "ama appeal" do
      let!(:hearing) { create(:hearing, :no_show, appeal: appeal) }
      let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }

      include_examples "creates task and timed hold task"

      context "when timer ends" do
        include_examples "closes NoShowHearingtask"
      end
    end

    context "legacy appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:hearing) do
        create(:legacy_hearing, appeal: appeal, disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS.key("no_show"))
      end
      let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }

      include_examples "creates task and timed hold task"

      context "when timer ends" do
        include_examples "closes NoShowHearingtask"
      end
    end
  end

  describe ".reschedule_hearing" do
    context "when all operations succeed" do
      it "closes existing tasks and creates new HearingTask and ScheduleHearingTask" do
        expect { no_show_hearing_task.reschedule_hearing }.to_not raise_error

        expect(hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(disposition_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(no_show_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)

        expect(distribution_task.children.count).to eq(2)
        expect(distribution_task.children.open.count).to eq(1)

        expect(distribution_task.children.open.first.type).to eq(HearingTask.name)
        expect(distribution_task.children.open.first.children.first.type).to eq(ScheduleHearingTask.name)

        expect(distribution_task.appeal.ready_for_distribution?).to eq(false)
      end
    end

    context "when an operation fails" do
      before { allow(ScheduleHearingTask).to receive(:create!).and_raise(StandardError) }
      it "does not commit any changes to the database" do
        expect { no_show_hearing_task.reschedule_hearing }.to raise_error(StandardError)

        expect(hearing_task.reload.open?).to eq(true)
        expect(disposition_task.reload.open?).to eq(true)
        expect(no_show_hearing_task.reload.open?).to eq(true)

        expect(distribution_task.children.count).to eq(1)

        expect(distribution_task.reload.appeal.ready_for_distribution?).to eq(false)
      end
    end
  end
end
