# frozen_string_literal: true

describe TranscriptionTask, :postgres do
  before do
    Time.zone = "Eastern Time (US & Canada)"
    TranscriptionTeam.singleton.add_user(transcription_user)
    RequestStore[:current_user] = transcription_user
  end

  let(:transcription_user) { create(:user) }

  context "#update_from_params" do
    context "When cancelled" do
      let(:update_params) do
        {
          status: Constants.TASK_STATUSES.cancelled
        }
      end
      let(:appeal) { create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal) }
      let!(:hearing_task) { create(:hearing_task, parent: root_task) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: hearing_task) }
      let!(:disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task.reload) }
      let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

      it "cancels all tasks in the hierarchy and creates a new schedule_hearing_task" do
        transcription_task.update_from_params(update_params, transcription_user)

        expect(hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(schedule_hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(disposition_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(root_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)

        new_hearing_task = root_task.children.where.not(status: Constants.TASK_STATUSES.cancelled).first
        new_schedule_hearing_task = new_hearing_task.children.first

        expect(new_hearing_task.open?).to eq(true)
        expect(new_hearing_task.type).to eq(HearingTask.name)
        expect(new_schedule_hearing_task.open?).to eq(true)
        expect(new_schedule_hearing_task.type).to eq(ScheduleHearingTask.name)
      end
    end

    context "When completed" do
      let(:update_params) do
        {
          status: Constants.TASK_STATUSES.completed
        }
      end
      let(:appeal) { create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal) }
      let!(:hearing_task) { create(:hearing_task, parent: root_task) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: hearing_task) }
      let!(:disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task) }
      let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

      it "completes the task" do
        transcription_task.update_from_params(update_params, transcription_user)

        expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
      end
    end
  end

  context "#hearing_task" do
    let(:appeal) { create(:appeal) }
    let!(:root_task) { create(:root_task, appeal: appeal) }
    let!(:hearing_task) { create(:hearing_task, parent: root_task) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: hearing_task) }
    let!(:disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task) }
    let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

    it "returns the hearing task" do
      expect(transcription_task.hearing_task).to eq(hearing_task)
    end
  end
end
