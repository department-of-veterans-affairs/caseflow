# frozen_string_literal: true

describe AttorneyLegacyTask, :postgres do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  context "#from_vacols" do
    subject { AttorneyLegacyTask.from_vacols(case_assignment, appeal, user) }

    let(:vacols_id) { "1111" }
    let(:appeal) { LegacyAppeal.create(vacols_id: vacols_id) }
    let(:user) { create(:user) }
    let(:case_assignment) do
      OpenStruct.new(
        vacols_id: vacols_id,
        date_due: 1.day.ago,
        assigned_to_location_date: 5.days.ago,
        created_at: 6.days.ago,
        docket_date: nil
      )
    end

    context "when there is information about the case assignment" do
      it "sets all the fields correctly" do
        expect(subject.user_id).to eq(user.css_id)
        expect(subject.id).to eq(vacols_id)
        expect(subject.assigned_on).to eq 5.days.ago.to_datetime
        expect(subject.task_id).to eq "1111-2015-01-24"
        expect(subject.started_at).to eq nil
      end

      context "when the user has viewed the appeal before" do
        before { AppealView.create(appeal: appeal, user: user, created_at: 5.days.ago) }

        it "sets the started_at timetamp" do
          expect(subject.started_at).to eq 5.days.ago
        end
      end
    end
  end
end
