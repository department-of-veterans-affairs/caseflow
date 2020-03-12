# frozen_string_literal: true

describe PostDecisionMotionDeleter, :all_dbs do
  let(:appeal) { create(:appeal, :with_straight_vacate_stream) }
  let(:vacate_stream) { Appeal.vacate.find_by(stream_docket_number: appeal.docket_number) }
  let(:task) { AttorneyTask.find_by(appeal: vacate_stream) }
  let(:instructions) { "formatted instructions from attorney" }

  subject { PostDecisionMotionDeleter.new(task, instructions) }

  describe "#process" do
    it "deletes the motion and stream, and creates a new judge task" do
      subject.process
      expect(JudgeAddressMotionToVacateTask.where(appeal: appeal).count).to eq 2
      expect(PostDecisionMotion.where(appeal: vacate_stream).count).to eq 0
      expect(Task.where(appeal_id: vacate_stream.id).count).to eq 0
      expect { vacate_stream.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when initialized with a task on an original appeal" do
      let(:task) { Task.find_by(appeal: appeal) }
      it "raises an error and no-ops" do
        expect { subject.process }.to raise_error StandardError
        expect_noop
      end
    end

    context "when initialized with a nil task" do
      let(:task) { nil }
      it "raises an error and no-ops" do
        expect { subject.process }.to raise_error StandardError
        expect_noop
      end
    end

    def expect_noop
      vacate_stream.reload
      expect(JudgeAddressMotionToVacateTask.where(appeal: appeal).count).to eq 1
      expect(PostDecisionMotion.where(appeal: vacate_stream).count).to eq 1
    end
  end
end
