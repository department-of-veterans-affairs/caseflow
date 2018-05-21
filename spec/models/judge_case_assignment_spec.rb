describe JudgeCaseAssignment do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let(:appeal) { LegacyAppeal.create(vacols_id: "123456") }

  before do
    allow_any_instance_of(User).to receive(:vacols_role).and_return("Judge")
  end

  context ".create" do
    subject do
      JudgeCaseAssignment.create(
        appeal_id: appeal_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to,
        appeal_type: appeal_type
      )
    end

    context "when all required values are present" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "it is successful" do
        expect(QueueRepository).to receive(:assign_case_to_attorney!).once
        expect(subject.valid?).to eq true
      end
    end

    context "when appeal id is not found" do
      let(:appeal_id) { 1234 }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "raises ActiveRecord::RecordNotFound" do
        expect(QueueRepository).to_not receive(:assign_case_to_attorney!)
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when appeal type is not valid" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Unknown" }

      it "does not assign case to attorney" do
        expect(QueueRepository).to_not receive(:assign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Appeal type is not included in the list"]
      end
    end

    context "when assigned by is missing" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { nil }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "does not assign case to attorney" do
        expect(QueueRepository).to_not receive(:assign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Assigned by can't be blank"]
      end
    end
  end

  context ".update" do
    subject do
      JudgeCaseAssignment.update(
        task_id: task_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to,
        appeal_type: appeal_type
      )
    end
    context "when all required values are present" do
      let(:task_id) { "3615398-2018-04-18" }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "it is successful" do
        expect(QueueRepository).to receive(:reassign_case_to_attorney!).once
        expect(subject.valid?).to eq true
      end
    end

    context "when task id is not valid" do
      let(:task_id) { 1234 }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "does not reassign case to attorney" do
        expect(QueueRepository).to_not receive(:reassign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Task is invalid"]
      end
    end

    context "when appeal type is not valid" do
      let(:task_id) { "3615398-2018-04-18" }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Unknown" }

      it "does not reassign case to attorney" do
        expect(QueueRepository).to_not receive(:reassign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Appeal type is not included in the list"]
      end
    end

    context "when assigned by is missing" do
      let(:task_id) { "3615398-2018-04-18" }
      let(:assigned_by) { nil }
      let(:assigned_to) { attorney }
      let(:appeal_type) { "Legacy" }

      it "does not reassign case to attorney" do
        expect(QueueRepository).to_not receive(:reassign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Assigned by can't be blank"]
      end
    end
  end
end
