# frozen_string_literal: true

describe CavcTask, :postgres do
  describe ".create" do
    subject { described_class.create(appeal: appeal, parent: parent_task) }
    let(:appeal) { create(:appeal) }
    let(:parent_task) { create(:distribution_task, appeal: appeal) }

    context "parent is DistributionTask" do
      it "creates task" do
        new_task = subject
        expect(new_task.valid?).to be true
        expect(new_task.errors.messages[:parent].empty?).to be true
        expect(appeal.tasks).to include(new_task)
        expect(parent_task.children).to include(new_task)
        # appeal.treee
      end
    end

    context "parent is not a DistributionTask" do
      let(:parent_task) { create(:root_task) }
      it "fails to create task" do
        new_task = subject
        expect(new_task.valid?).to be false
        expect(new_task.errors.messages[:parent]).to include("parent should be a DistributionTask")
        # binding.pry
      end
    end

    context "parent is nil" do
      let(:parent_task) { nil }
      it "fails to create task" do
        new_task = subject
        expect(new_task.valid?).to be false
        expect(new_task.errors.messages[:parent].empty?).to be false
        expect(new_task.errors.messages[:parent]).to include("can't be blank")
      end
    end
  end

  describe ".create_change_hearing_disposition_task" do
  #   let(:appeal) { create(:appeal) }
  #   let(:root_task) { create(:root_task, appeal: appeal) }
  #   let(:hearing_task) { create(:hearing_task, parent: root_task) }
  #   let(:instructions) { "These are the instructions I've written for you." }
  #   let!(:disposition_task) do
  #     create(
  #       :assign_hearing_disposition_task,
  #       :in_progress,
  #       parent: hearing_task
  #     )
  #   end
  #   let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }
  #
  #   subject { hearing_task.create_change_hearing_disposition_task(instructions) }
  #
  #   it "completes the disposition task and its children and creates a new change hearing disposition task" do
  #     expect(disposition_task.status).to_not eq Constants.TASK_STATUSES.completed
  #     expect(ChangeHearingDispositionTask.count).to eq 0
  #
  #     subject
  #
  #     expect(disposition_task.reload.status).to eq Constants.TASK_STATUSES.completed
  #     expect(transcription_task.reload.status).to eq Constants.TASK_STATUSES.completed
  #     expect(ChangeHearingDispositionTask.count).to eq 1
  #     change_hearing_disposition_task = ChangeHearingDispositionTask.last
  #     expect(change_hearing_disposition_task.appeal).to eq appeal
  #     expect(change_hearing_disposition_task.parent).to eq hearing_task
  #     expect(change_hearing_disposition_task.open?).to be_truthy
  #     expect(change_hearing_disposition_task.instructions).to include(instructions)
  #   end
  end

  describe "#assign_hearing_disposition_task" do
  #   let(:root_task) { create(:root_task) }
  #   let(:hearing_task) { create(:hearing_task, parent: root_task) }
  #   let(:disposition_task_type) { :assign_hearing_disposition_task }
  #   let(:trait) { :assigned }
  #   let!(:disposition_task) do
  #     create(
  #       disposition_task_type,
  #       trait,
  #       parent: hearing_task
  #     )
  #   end
  #
  #   subject { hearing_task.disposition_task }
  #
  #   it "returns the disposition task" do
  #     expect(subject).to eq disposition_task
  #   end
  #
  #   context "the disposition task is not active" do
  #     let(:trait) { :cancelled }
  #
  #     it "returns nil" do
  #       expect(subject).to be_nil
  #     end
  #   end
  #
  #   context "it's a ChangeHearingDispositionTask" do
  #     let(:disposition_task_type) { :change_hearing_disposition_task }
  #
  #     it "returns nil" do
  #       expect(subject).to be_nil
  #     end
  #   end
  end
end
