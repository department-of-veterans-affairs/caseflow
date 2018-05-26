describe AttorneyLegacyTask do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let(:appeal) { LegacyAppeal.create(vacols_id: "123456") }

  before do
    allow_any_instance_of(User).to receive(:vacols_role).and_return("Judge")
  end

  context ".create" do
    subject do
      AttorneyLegacyTask.create(
        appeal_id: appeal_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to
      )
    end

    context "when all required values are present" do
      let(:appeal_id) { appeal.id }
      let(:assigned_by) { judge }
      let(:assigned_to) { attorney }

      it "it is successful" do
        expect(QueueRepository).to receive(:assign_case_to_attorney!).once
        expect(subject.valid?).to eq true
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
      AttorneyLegacyTask.update(
        task_id: task_id,
        assigned_by: assigned_by,
        assigned_to: assigned_to
      )
    end
    context "when all required values are present" do
      let(:task_id) { "3615398-2018-04-18" }
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

  context "#from_vacols" do
    subject { AttorneyLegacyTask.from_vacols(case_assignment, User.new(css_id: "USER_ID")) }

    context "when there is information about the case assignment" do
      let(:case_assignment) do
        OpenStruct.new(
          vacols_id: "1111",
          date_due: 1.day.ago,
          assigned_to_attorney_date: 5.days.ago,
          created_at: 6.days.ago,
          docket_date: nil
        )
      end

      it "sets all the fields correctly" do
        expect(subject.user_id).to eq("USER_ID")
        expect(subject.id).to eq("1111")
        expect(subject.due_on).to eq 1.day.ago
        expect(subject.assigned_on).to eq 5.days.ago
        expect(subject.task_id).to eq "1111-2015-01-24"
      end
    end
  end
end
