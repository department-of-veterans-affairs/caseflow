# frozen_string_literal: true

require "rails_helper"

describe HearingTask do
  describe ".create_change_hearing_disposition_task" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let(:instructions) { "These are the instructions I've written for you." }
    let!(:disposition_task) do
      FactoryBot.create(
        :assign_hearing_disposition_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.in_progress
      )
    end
    let!(:transcription_task) { create(:transcription_task, parent: disposition_task, appeal: appeal) }

    subject { hearing_task.create_change_hearing_disposition_task(instructions) }

    it "completes the disposition task and its children and creates a new change hearing disposition task" do
      expect(disposition_task.status).to_not eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 0

      subject

      expect(disposition_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(transcription_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 1
      change_hearing_disposition_task = ChangeHearingDispositionTask.last
      expect(change_hearing_disposition_task.appeal).to eq appeal
      expect(change_hearing_disposition_task.parent).to eq hearing_task
      expect(change_hearing_disposition_task.open?).to be_truthy
      expect(change_hearing_disposition_task.instructions).to match_array [instructions]
    end
  end

  describe "#assign_hearing_disposition_task" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: root_task.appeal) }
    let(:disposition_task_type) { :assign_hearing_disposition_task }
    let(:disposition_task_status) { Constants.TASK_STATUSES.assigned }
    let!(:disposition_task) do
      FactoryBot.create(
        disposition_task_type,
        parent: hearing_task,
        appeal: root_task.appeal,
        status: disposition_task_status
      )
    end

    subject { hearing_task.disposition_task }

    it "returns the disposition task" do
      expect(subject).to eq disposition_task
    end

    context "the disposition task is not active" do
      let(:disposition_task_status) { Constants.TASK_STATUSES.cancelled }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "it's a ChangeHearingDispositionTask" do
      let(:disposition_task_type) { :change_hearing_disposition_task }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
