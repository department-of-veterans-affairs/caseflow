# frozen_string_literal: true

describe PreDocketTask, :all_dbs do
  describe ".create_pre_docket_task!" do
    let(:appeal) { create(:appeal) }

    subject { described_class.create_pre_docket_task!(appeal) }

    context "create a new PreDocketTask" do
      it "creates a PreDocketTask and its status is on_hold" do
        expect(PreDocketTask.all.count).to eq 0

        subject

        expect(PreDocketTask.all.count).to eq 1
        expect(PreDocketTask.first.appeal).to eq appeal
        expect(PreDocketTask.first.assigned_to).to eq Bva.singleton
        expect(PreDocketTask.first.status).to eq Constants.TASK_STATUSES.on_hold
      end
    end
  end
end
