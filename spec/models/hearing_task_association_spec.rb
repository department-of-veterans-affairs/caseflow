# frozen_string_literal: true

describe HearingTaskAssociation do
  describe "uniqueness validation" do
    let(:hearing) { nil }
    let(:status) { Constants.TASK_STATUSES.in_progress }
    let(:hearing_task) { FactoryBot.create(:hearing_task, appeal: hearing&.appeal, status: status) }
    let(:hearing_task_2) do
      FactoryBot.create(:hearing_task, appeal: hearing&.appeal, status: Constants.TASK_STATUSES.assigned)
    end
    let!(:hearing_task_association) do
      FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task)
    end
    let(:message) do
      "Validation failed: Hearing task that is not closed " \
        "already exists for #{hearing&.class&.name} #{hearing&.id}"
    end

    subject { FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2) }

    context "legacy hearing" do
      let(:hearing) { create(:legacy_hearing) }

      it "doesn't allow creation of a duplicate" do
        before_count = HearingTaskAssociation.count
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).with_message(message)
        expect(HearingTaskAssociation.count).to eq before_count
      end

      context "there is a duplicate hearing task but it's closed" do
        let(:status) { Constants.TASK_STATUSES.cancelled }

        it "allows creation of a duplicate" do
          before_count = HearingTaskAssociation.count
          expect { subject }.to_not raise_error
          expect(HearingTaskAssociation.count).to eq before_count + 1
        end
      end
    end

    context "ama hearing" do
      let(:hearing) { create(:hearing) }

      it "doesn't allow creation of a duplicate" do
        before_count = HearingTaskAssociation.count
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).with_message(message)
        expect(HearingTaskAssociation.count).to eq before_count
      end

      context "there is a duplicate hearing task but it's closed" do
        let(:status) { Constants.TASK_STATUSES.cancelled }

        it "allows creation of a duplicate" do
          before_count = HearingTaskAssociation.count
          expect { subject }.to_not raise_error
          expect(HearingTaskAssociation.count).to eq before_count + 1
        end
      end
    end
  end
end
