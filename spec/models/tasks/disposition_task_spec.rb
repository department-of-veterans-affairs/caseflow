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

  describe ".mark_no_show!" do
    let(:disposition) { nil }
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let(:hearing) { FactoryBot.create(:hearing, appeal: appeal, disposition: disposition) }
    let!(:hearing_task_association) do
      FactoryBot.create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: hearing_task
      )
    end
    let!(:schedule_hearing_task) do
      FactoryBot.create(
        :schedule_hearing_task,
        parent: hearing_task,
        appeal: appeal,
        assigned_to: HearingsManagement.singleton,
        status: Constants.TASK_STATUSES.completed
      )
    end
    let!(:disposition_task) do
      FactoryBot.create(
        :ama_disposition_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.in_progress
      )
    end

    subject { disposition_task.mark_no_show! }

    context "the hearing's diposition is 'no_show'" do
      let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }

      it "marks the disposition task as no_show" do
        expect(disposition_task.status).to eq Constants.TASK_STATUSES.in_progress
        expect(NoShowHearingTask.count).to eq 0

        subject

        expect(disposition_task.status).to eq Constants.TASK_STATUSES.on_hold
        no_show_hearing_task = NoShowHearingTask.first
        expect(no_show_hearing_task).to_not be_nil
        expect(no_show_hearing_task.placed_on_hold_at).to_not be_nil
        expect(no_show_hearing_task.on_hold_expired?).to be_falsey
        expect(no_show_hearing_task.status).to eq Constants.TASK_STATUSES.on_hold
        expect(no_show_hearing_task.on_hold_duration).to eq 25.days
      end
    end

    context "the hearing's disposition is nil" do
      let(:disposition) { nil }

      it "raises an error" do
        expect { subject }.to raise_error DispositionTask::HearingDispositionNotNoShow
        expect(disposition_task.status).to eq Constants.TASK_STATUSES.in_progress
      end
    end
  end
end
