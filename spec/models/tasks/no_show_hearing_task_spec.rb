# frozen_string_literal: true

describe NoShowHearingTask do
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
  let(:distribution_task) { FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task) }

  describe ".create!" do
    it "is automatically assigned to the HearingAdmin organization" do
      expect(NoShowHearingTask.create!(appeal: appeal, parent: root_task).assigned_to).to eq(HearingAdmin.singleton)
    end
  end

  describe ".reschedule_hearing" do
    let(:parent_hearing_task) { FactoryBot.create(:hearing_task, parent: distribution_task, appeal: appeal) }
    let!(:completed_scheduling_task) do
      FactoryBot.create(:schedule_hearing_task, :completed, parent: parent_hearing_task, appeal: appeal)
    end
    let(:disposition_task) { FactoryBot.create(:disposition_task, parent: parent_hearing_task, appeal: appeal) }
    let(:no_show_hearing_task) do
      FactoryBot.create(:no_show_hearing_task, parent: disposition_task, appeal: appeal)
    end

    context "when all operations succeed" do
      it "closes existing tasks and creates new HearingTask and ScheduleHearingTask" do
        expect { no_show_hearing_task.reschedule_hearing }.to_not raise_error

        expect(parent_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(disposition_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(no_show_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)

        expect(distribution_task.children.count).to eq(2)
        expect(distribution_task.children.active.count).to eq(1)

        expect(distribution_task.children.active.first.type).to eq(HearingTask.name)
        expect(distribution_task.children.active.first.children.first.type).to eq(ScheduleHearingTask.name)

        expect(distribution_task.ready_for_distribution?).to eq(false)
      end
    end

    context "when an operation fails" do
      before { allow(ScheduleHearingTask).to receive(:create!).and_raise(StandardError) }
      it "does not commit any changes to the database" do
        expect { no_show_hearing_task.reschedule_hearing }.to raise_error

        expect(parent_hearing_task.reload.active?).to eq(true)
        expect(disposition_task.reload.active?).to eq(true)
        expect(no_show_hearing_task.reload.active?).to eq(true)

        expect(distribution_task.children.count).to eq(1)

        expect(distribution_task.reload.ready_for_distribution?).to eq(false)
      end
    end
  end
end
