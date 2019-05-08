# frozen_string_literal: true

describe HearingTask do
  describe "#create_change_hearing_disposition_task_and_complete_children" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: root_task.appeal) }
    let!(:disposition_task) { FactoryBot.create(:disposition_task, parent: hearing_task, appeal: root_task.appeal) }
    let(:instructions) { "Hello, please read these instructions." }

    subject { hearing_task.create_change_hearing_disposition_task_and_complete_children(instructions) }

    it "calls create_change_hearing_disposition_task_and_complete on the disposition task" do
      allow(hearing_task)
        .to receive_message_chain(:children, :active, :find_by)
        .with(type: [DispositionTask.name, ChangeHearingDispositionTask.name])
        .and_return(disposition_task)
      expect(disposition_task).to receive(:create_change_hearing_disposition_task_and_complete).with(instructions)

      subject
    end
  end

  describe "#disposition_task" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: root_task.appeal) }
    let(:disposition_task_type) { :disposition_task }
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
