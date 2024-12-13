# frozen_string_literal: true

describe JudgeCaseAssignmentToAttorney, :all_dbs do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let(:vacols_case) { create(:case, bfcurloc: judge_staff.slogid) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:instructions) { "Complete the review and draft a decision." }

  let!(:judge_staff) do
    create(:staff, :judge_role, slogid: "BVABAWS", sdomainid: judge.css_id)
  end

  before do
    allow_any_instance_of(User).to receive(:vacols_roles).and_return(["judge"])
  end

  context ".create" do
    subject do
      JudgeCaseAssignmentToAttorney.create(
        appeal_id: appeal_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to,
        instructions: instructions
      )
    end

    context "when all required values are present" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "is successful and passes instructions" do
        expect(QueueRepository).to receive(:assign_case_to_attorney!).with(
          hash_including(instructions: [instructions])
        ).once

        expect(subject.valid?).to eq true
        expect(subject.errors).to be_empty
      end
    end

    context "when instructions are missing" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:instructions) { nil }

      it "is successful and uses an empty array for instructions" do
        expect(QueueRepository).to receive(:assign_case_to_attorney!).with(
          hash_including(instructions: [])
        ).once

        expect(subject.valid?).to eq true
        expect(subject.errors).to be_empty
      end
    end

    context "when instructions are not an array" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }
      let(:instructions) { "Draft decision memo." }

      it "normalizes instructions into an array" do
        expect(QueueRepository).to receive(:assign_case_to_attorney!).with(
          hash_including(instructions: ["Draft decision memo."])
        ).once

        expect(subject.valid?).to eq true
        expect(subject.errors).to be_empty
      end
    end

    context "when user does not have access" do
      let(:appeal_id) { create(:legacy_appeal, vacols_case: create(:case)).id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "should raise Caseflow::Error::UserRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::LegacyCaseAlreadyAssignedError)
      end
    end

    context "when appeal id is not found" do
      let(:appeal_id) { 1234 }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "raises ActiveRecord::RecordNotFound" do
        expect(QueueRepository).to_not receive(:assign_case_to_attorney!)
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when assigned by is missing" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { nil }
      let(:assigned_to) { attorney }

      it "does not assign case to attorney" do
        expect(QueueRepository).to_not receive(:assign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Assigned by can't be blank"]
      end
    end
  end

  context ".update" do
    subject do
      JudgeCaseAssignmentToAttorney.update(
        task_id: task_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to
      )
    end
    context "when all required values are present" do
      let(:task_id) { "#{appeal.vacols_id}-2018-04-18" }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "it is successful" do
        expect(QueueRepository).to receive(:reassign_case_to_attorney!).once
        expect(subject.valid?).to eq true
      end
    end

    context "when task id is not valid" do
      let(:task_id) { 1234 }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "does not reassign case to attorney" do
        expect(QueueRepository).to_not receive(:reassign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Task is invalid"]
      end
    end

    context "when assigned by is missing" do
      let(:task_id) { "3615398-2018-04-18" }
      let(:assigned_by) { nil }
      let(:assigned_to) { attorney }

      it "does not reassign case to attorney" do
        expect(QueueRepository).to_not receive(:reassign_case_to_attorney!)
        expect(subject.valid?).to eq false
        expect(subject.errors.full_messages).to eq ["Assigned by can't be blank"]
      end
    end
  end
end
