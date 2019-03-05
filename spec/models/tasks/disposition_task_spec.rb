# frozen_string_literal: true

describe DispositionTask do
  describe ".create_disposition_task!" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:parent) { nil }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }

    subject { described_class.create_disposition_task!(appeal, parent, hearing) }

    context "parent is a HearingTask" do
      let(:parent) { FactoryBot.create(:hearing_task, appeal: appeal) }

      it "creates a DispositionTask and a HearingTaskAssociation" do
        expect(DispositionTask.all.count).to eq 0
        expect(HearingTaskAssociation.all.count).to eq 0

        subject

        expect(DispositionTask.all.count).to eq 1
        expect(DispositionTask.first.appeal).to eq appeal
        expect(DispositionTask.first.parent).to eq parent
        expect(DispositionTask.first.assigned_to).to eq Bva.singleton
        expect(HearingTaskAssociation.all.count).to eq 1
        expect(HearingTaskAssociation.first.hearing).to eq hearing
        expect(HearingTaskAssociation.first.hearing_task).to eq parent
      end
    end

    context "parent is a RootTask" do
      let(:parent) { FactoryBot.create(:root_task, appeal: appeal) }

      it "should throw an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
      end
    end
  end

  describe ".cancel!" do
    let(:disposition) { nil }
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let!(:hearing_task) { create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal, disposition: disposition) }
    let!(:disposition_task) do
      create(:ama_disposition_task, parent: hearing_task, appeal: appeal, status: Constants.TASK_STATUSES.in_progress)
    end

    subject { disposition_task.cancel! }

    context "the task's hearing's disposition is cancelled" do
      let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

      it "cancels the disposition task" do
        expect(disposition_task.status).to_not eq Constants.TASK_STATUSES.cancelled
        expect { subject }.to_not raise_error
        expect(disposition_task.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end
end
