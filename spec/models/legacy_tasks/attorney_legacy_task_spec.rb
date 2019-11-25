# frozen_string_literal: true

describe AttorneyLegacyTask, :postgres do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  context "#from_vacols" do
    subject do
      AttorneyLegacyTask.from_vacols(
        case_assignment,
        LegacyAppeal.create(vacols_id: "1111"),
        User.new(css_id: "USER_ID")
      )
    end

    context "when there is information about the case assignment" do
      let(:case_assignment) do
        vacols_id = "1111"
        OpenStruct.new(
          vacols_id: vacols_id,
          date_due: 1.day.ago,
          assigned_to_location_date: 5.days.ago,
          created_at: 6.days.ago,
          docket_date: nil
        )
      end

      it "sets all the fields correctly" do
        expect(subject.user_id).to eq("USER_ID")
        expect(subject.id).to eq("1111")
        expect(subject.assigned_on).to eq 5.days.ago.to_date
        expect(subject.task_id).to eq "1111-2015-01-24"
      end
    end
  end

  context "#hide_from_case_timeline" do
    subject do
      AttorneyLegacyTask.from_vacols(
        case_assignment,
        LegacyAppeal.create(vacols_id: "1111"),
        User.new(css_id: "USER_ID")
      )
    end

    let(:case_assignment) do
      vacols_id = "1111"
      OpenStruct.new(
        vacols_id: vacols_id,
        date_due: 1.day.ago,
        assigned_to_location_date: 5.days.ago,
        created_at: 6.days.ago,
        docket_date: nil
      )
    end

    it "should alwayse be false" do
      expect(subject.hide_from_case_timeline).to eq(false)
    end
  end

  context "#hide_from_task_snapshot" do
    subject do
      AttorneyLegacyTask.from_vacols(
        case_assignment,
        LegacyAppeal.create(vacols_id: "1111"),
        User.new(css_id: "USER_ID")
      )
    end

    let(:case_assignment) do
      vacols_id = "1111"
      OpenStruct.new(
        vacols_id: vacols_id,
        date_due: 1.day.ago,
        assigned_to_location_date: 5.days.ago,
        created_at: 6.days.ago,
        docket_date: nil
      )
    end

    it "should alwayse be false" do
      expect(subject.hide_from_task_snapshot).to eq(false)
    end
  end
end
