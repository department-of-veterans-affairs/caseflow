# frozen_string_literal: true

require "rails_helper"

describe NoShowHearingTask do
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
  let(:distribution_task) { FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task) }
  let(:hearing_task) { FactoryBot.create(:hearing_task, parent: distribution_task, appeal: appeal) }
  let!(:completed_scheduling_task) do
    FactoryBot.create(:schedule_hearing_task, :completed, parent: hearing_task, appeal: appeal)
  end
  let(:disposition_task) { FactoryBot.create(:assign_hearing_disposition_task, parent: hearing_task, appeal: appeal) }
  let(:no_show_hearing_task) { FactoryBot.create(:no_show_hearing_task, parent: disposition_task, appeal: appeal) }

  context "create a new NoShowHearingTask" do
    let(:task_params) { { appeal: appeal, parent: disposition_task } }

    subject { NoShowHearingTask.create!(**task_params) }

    it "is assigned to the HearingsManagement org by default" do
      expect(subject.assigned_to_type).to eq "Organization"
      expect(subject.assigned_to).to eq HearingsManagement.singleton
    end

    context "there is a hearings management org user" do
      let!(:hearings_management_user) { FactoryBot.create(:hearings_coordinator) }

      before do
        OrganizationsUser.add_user_to_organization(hearings_management_user, HearingsManagement.singleton)
      end

      it "has actions available to the hearings managment org member" do
        expect(subject.available_actions_unwrapper(hearings_management_user).count).to be > 0
      end
    end

    context "there is a hearing admin org user" do
      let(:hearing_admin_user) { FactoryBot.create(:user, station_id: 101) }

      before do
        OrganizationsUser.add_user_to_organization(hearing_admin_user, HearingAdmin.singleton)
      end

      it "has one action available to the hearing admin user" do
        expect(subject.available_actions_unwrapper(hearing_admin_user).count).to eq 1
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

        expect(distribution_task.ready_for_distribution?).to eq(false)
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

        expect(distribution_task.reload.ready_for_distribution?).to eq(false)
      end
    end
  end

  describe "completing a child HearingAdminActionTask" do
    let!(:hearing_admin_action_task) do
      HearingAdminActionVerifyPoaTask.create!(
        appeal: appeal,
        parent: no_show_hearing_task,
        assigned_to: HearingsManagement.singleton
      )
    end

    it "sets the status of the parent NoShowHearingTask to assigned" do
      expect(no_show_hearing_task.status).to eq(Constants.TASK_STATUSES.on_hold)
      hearing_admin_action_task.update!(status: Constants.TASK_STATUSES.completed)
      expect(no_show_hearing_task.status).to eq(Constants.TASK_STATUSES.assigned)
    end
  end
end
