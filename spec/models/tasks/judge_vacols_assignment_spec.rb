describe JudgeVacolsAssignment do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end
  context "#from_vacols" do
    subject { JudgeVacolsAssignment.from_vacols(case_assignment, "USER_ID") }

    context "when there is information about the case assignment" do
      let(:case_assignment) do
        OpenStruct.new(vacols_id: "1111",
                       date_due: 1.day.ago,
                       reassigned_to_judge_date: reassigned_to_judge_date,
                       docket_date: nil,
                       created_at: 5.days.ago,
                       assigned_to_location_date: 6.months.ago,
                       document_id: "173341517.524")
      end

      context "when a case has been reaasigned back to judge" do
        let(:reassigned_to_judge_date) { 5.days.ago }

        it "sets all the fields correctly" do
          expect(subject.user_id).to eq("USER_ID")
          expect(subject.id).to eq("1111")
          expect(subject.due_on).to eq 1.day.ago
          expect(subject.assigned_on).to eq 5.days.ago
          expect(subject.task_type).to eq "Review"
          expect(subject.task_id).to eq "1111-2015-01-25"
          expect(subject.document_id).to eq "173341517.524"
        end
      end

      context "when a case is ready to be assigned to an attorney" do
        let(:reassigned_to_judge_date) { nil }

        it "sets all the fields correctly" do
          expect(subject.user_id).to eq("USER_ID")
          expect(subject.id).to eq("1111")
          expect(subject.due_on).to eq 1.day.ago
          expect(subject.assigned_on).to eq 6.months.ago
          expect(subject.task_type).to eq "Assign"
          expect(subject.task_id).to eq "1111-2015-01-25"
        end
      end
    end
  end
end
