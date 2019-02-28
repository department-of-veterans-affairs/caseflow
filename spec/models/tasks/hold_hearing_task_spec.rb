describe HoldHearingTask do
  describe ".create_hold_hearing_task!" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:parent) { nil }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }

    subject { described_class.create_hold_hearing_task!(appeal, parent, hearing) }

    context "parent is a HearingTask" do
      let(:parent) { FactoryBot.create(:hearing_task, appeal: appeal) }

      it "creates a HoldHearingTask and a HearingTaskAssociation" do
        expect(HoldHearingTask.all.count).to eq 0
        expect(HearingTaskAssociation.all.count).to eq 0

        subject

        expect(HoldHearingTask.all.count).to eq 1
        expect(HoldHearingTask.first.appeal).to eq appeal
        expect(HoldHearingTask.first.parent).to eq parent
        expect(HoldHearingTask.first.assigned_to).to eq Bva.singleton
        expect(HearingTaskAssociation.all.count).to eq 1
        expect(HearingTaskAssociation.first.hearing).to eq hearing
        expect(HearingTaskAssociation.first.hearing_task).to eq parent
      end
    end

    context "parent is a RootTask" do
      let(:parent) { FactoryBot.create(:root_task, appeal: appeal) }

      it "creates a HoldHearingTask but no HearingTaskAssociation" do
        expect(HoldHearingTask.all.count).to eq 0
        expect(HearingTaskAssociation.all.count).to eq 0

        subject

        expect(HoldHearingTask.all.count).to eq 1
        expect(HoldHearingTask.first.appeal).to eq appeal
        expect(HoldHearingTask.first.parent).to eq parent
        expect(HoldHearingTask.first.assigned_to).to eq Bva.singleton
        expect(HearingTaskAssociation.all.count).to eq 0
      end
    end
  end
end
