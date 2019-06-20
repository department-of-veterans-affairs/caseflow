# frozen_string_literal: true

describe HearingTaskAssociation do
  describe "uniqueness validation" do
    let(:hearing) { nil }
    let(:hearing_task) { FactoryBot.create(:hearing_task, appeal: hearing&.appeal) }
    let!(:hearing_task_association) do
      FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task)
    end
    let(:message) do
      "Validation failed: Hearing task association already exists for " \
        "#{hearing&.class&.name} #{hearing&.id} and HearingTask #{hearing_task.id}"
    end

    subject { FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }

    context "legacy hearing" do
      let(:hearing) { create(:legacy_hearing) }

      it "doesn't allow creation of a duplicate" do
        before_count = HearingTaskAssociation.count

        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).with_message(message)
        expect(HearingTaskAssociation.count).to eq before_count
      end
    end

    context "ama hearing" do
      let(:hearing) { create(:hearing) }

      it "doesn't allow creation of a duplicate" do
        before_count = HearingTaskAssociation.count
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).with_message(message)
        expect(HearingTaskAssociation.count).to eq before_count
      end
    end
  end
end
