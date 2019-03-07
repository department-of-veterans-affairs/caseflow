# frozen_string_literal: true

describe NoShowHearingTask do
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }

  describe ".create!" do
    it "is automatically assigned to the HearingAdmin organization" do
      expect(NoShowHearingTask.create!(appeal: appeal, parent: root_task).assigned_to).to eq(HearingAdmin.singleton)
    end
  end

  describe ".reschedule_hearing" do
    let(:parent_hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:completed_scheduling_task) do
      FactoryBot.create(:schedule_hearing_task, :completed, parent: parent_hearing_task, appeal: appeal)
    end
    let(:disposition_task) { FactoryBot.create(:ama_disposition_task, parent: parent_hearing_task, appeal: appeal) }
    let(:no_show_hearing_task) do
      FactoryBot.create(:no_show_hearing_task, parent: disposition_task, appeal: appeal)
    end

    it "closes existing tasks and creates new HearingTask and ScheduleHearingTask" do
      expect { no_show_hearing_task.reschedule_hearing }.to_not raise_error

      expect(parent_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
      expect(disposition_task.status).to eq(Constants.TASK_STATUSES.completed)
      expect(no_show_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)

      expect(root_task.children.count).to eq(2)
      expect(root_task.children.active.count).to eq(1)

      expect(root_task.children.active.first.type).to eq(HearingTask.name)
      expect(root_task.children.active.first.children.first.type).to eq(ScheduleHearingTask.name)
    end
  end
end
