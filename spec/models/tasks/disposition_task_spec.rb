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
end
