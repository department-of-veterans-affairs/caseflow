describe VacolsAssignment do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end
  context "#from_vacols" do
    subject { VacolsAssignment.from_vacols(case_assignment, "USER_ID") }

    context "when there is no information about the case assignment" do
      let(:case_assignment) do
        OpenStruct.new(vacols_id: "1111", date_due: nil, date_assigned: nil, docket_date: nil)
      end

      it "sets all the fields correctly" do
        expect(subject.user_id).to eq("USER_ID")
        expect(subject.id).to eq("1111")
        expect(subject.due_on).to eq nil
        expect(subject.assigned_on).to eq nil
        expect(subject.task_id).to eq nil
      end
    end

    context "when there is information about the case assignment" do
      let(:case_assignment) do
        OpenStruct.new(vacols_id: "1111", date_due: 1.day.ago, date_assigned: 5.days.ago)
      end

      it "sets all the fields correctly" do
        expect(subject.user_id).to eq("USER_ID")
        expect(subject.id).to eq("1111")
        expect(subject.due_on).to eq 1.day.ago
        expect(subject.assigned_on).to eq 5.days.ago
        expect(subject.task_id).to eq "1111-2015-01-25"
      end
    end
  end
end
