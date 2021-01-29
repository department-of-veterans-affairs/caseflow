# frozen_string_literal: true

describe TranscriptionTask, :postgres do
  before do
    Time.zone = "Eastern Time (US & Canada)"
    TranscriptionTeam.singleton.add_user(transcription_user)
    RequestStore[:current_user] = transcription_user
  end

  let(:transcription_user) { create(:user) }

  context "check_parent_type" do
    let(:parent_task_type) { :hearing_task }
    let(:grand_parent_task_type) { :assign_hearing_disposition_task }
    let(:grand_parent_task) { create(grand_parent_task_type) }
    let(:parent_task) { create(parent_task_type, parent: grand_parent_task) }

    before { allow_any_instance_of(Task).to receive(:automatically_assign_org_task?).and_return(false) }

    subject { create(:transcription_task, parent: parent_task) }

    shared_examples "valid parent type" do
      it "does not throw an error" do
        expect { subject }.not_to raise_error
        expect(parent_task.children.length).to eq 1
        expect(parent_task.children.first.type).to eq TranscriptionTask.name
      end
    end

    it "throws an error because parent task type is invalid" do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid).with_message("Validation failed: Parent should " \
        "be one of AssignHearingDispositionTask, MissingHearingTranscriptsColocatedTask, TranscriptionTask, " \
        "DistributionTask")
      expect(parent_task.children.length).to eq 0
    end

    context "when the task type is valid" do
      context "transcription_task" do
        let(:parent_task_type) { :transcription_task }

        it_behaves_like "valid parent type"
      end

      context "assign_hearing_disposition_task" do
        let(:grand_parent_task_type) { :hearing_task }
        let(:parent_task_type) { :assign_hearing_disposition_task }

        it_behaves_like "valid parent type"
      end

      context "missing_hearing_transcripts_colocated_task" do
        let(:parent_task) { create(:ama_colocated_task, :missing_hearing_transcripts, parent: grand_parent_task) }

        # missing_hearing_transcripts automatically create a child transcription task
        subject { create(parent_task_type, parent: grand_parent_task) }

        it_behaves_like "valid parent type"
      end
    end
  end

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
