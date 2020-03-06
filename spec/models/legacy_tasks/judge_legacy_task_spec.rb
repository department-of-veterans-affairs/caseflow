# frozen_string_literal: true

describe JudgeLegacyTask, :postgres do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end
  context "#from_vacols" do
    subject do
      JudgeLegacyTask.from_vacols(
        case_assignment,
        LegacyAppeal.create(vacols_id: "1111"),
        User.new(css_id: "USER_ID")
      )
    end

    context "when there is information about the case assignment" do
      let(:case_assignment) do
        vacols_id = "1111"
        OpenStruct.new(vacols_id: vacols_id,
                       date_due: 1.day.ago,
                       reassigned_to_judge_date: reassigned_to_judge_date,
                       docket_date: nil,
                       created_at: 5.days.ago,
                       assigned_to_location_date: 3.days.ago,
                       assigned_to_attorney_date: assigned_to_attorney_date,
                       document_id: "173341517.524",
                       assigned_by: OpenStruct.new(first_name: "Joe", last_name: "Snuffy"))
      end

      context "when a case has been reaasigned back to judge" do
        let(:reassigned_to_judge_date) { 5.days.ago }
        let(:assigned_to_attorney_date) { 10.days.ago }

        it "sets all the fields correctly" do
          expect(subject.user_id).to eq("USER_ID")
          expect(subject.id).to eq("1111")
          expect(subject.assigned_on).to eq 3.days.ago.to_date
          expect(subject.task_id).to eq "1111-2015-01-25"
          expect(subject.document_id).to eq "173341517.524"
          expect(subject.assigned_by_first_name).to eq "Joe"
          expect(subject.assigned_by_last_name).to eq "Snuffy"
          expect(subject.previous_task.assigned_at).to eq 10.days.ago.to_date
        end
      end

      context "when a case is ready to be assigned to an attorney" do
        let(:reassigned_to_judge_date) { nil }
        let(:assigned_to_attorney_date) { nil }

        it "sets all the fields correctly" do
          expect(subject.user_id).to eq("USER_ID")
          expect(subject.id).to eq("1111")
          expect(subject.assigned_on).to eq 3.days.ago.to_date
          expect(subject.task_id).to eq "1111-2015-01-25"
          expect(subject.previous_task).to eq nil
        end
      end
    end
  end
end
