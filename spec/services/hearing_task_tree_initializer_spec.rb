# frozen_string_literal: true

describe HearingTaskTreeInitializer do
  context "#create_schedule_hearing_tasks" do
    context "when missing legacy appeals" do
      let!(:cases) { create_list(:case, 10, bfcurloc: "57", bfhr: "1") }

      it "creates the legacy appeal and creates schedule hearing tasks", skip: "flake on last expect" do
        described_class.create_schedule_hearing_tasks

        expect(LegacyAppeal.all.pluck(:vacols_id)).to match_array(cases.pluck(:bfkey))
        expect(ScheduleHearingTask.all.pluck(:appeal_id)).to match_array(LegacyAppeal.all.pluck(:id))
        expect(ScheduleHearingTask.first.parent.type).to eq(HearingTask.name)
        expect(ScheduleHearingTask.first.parent.parent.type).to eq(RootTask.name)
        expect(VACOLS::Case.all.pluck(:bfcurloc).uniq).to eq([LegacyAppeal::LOCATION_CODES[:caseflow]])
      end
    end

    context "when some legacy appeals already have schedule hearing tasks" do
      let!(:cases) { create_list(:case, 5, bfcurloc: "57", bfhr: "1") }

      it "doesn't duplicate tasks" do
        described_class.create_schedule_hearing_tasks

        more_cases = create_list(:case, 5, bfcurloc: "57", bfhr: "1")
        described_class.create_schedule_hearing_tasks

        expect(LegacyAppeal.all.pluck(:vacols_id)).to match_array((cases + more_cases).pluck(:bfkey))
        expect(ScheduleHearingTask.all.pluck(:appeal_id)).to match_array(LegacyAppeal.all.pluck(:id))
      end
    end
  end

  context "#cases_that_need_hearings" do
    let!(:case_without_hearing) { create(:case, bfcurloc: "57", bfhr: "1") }
    let!(:case_with_closed_hearing) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: [create(:case_hearing, hearing_disp: "H")]
      )
    end
    let!(:case_with_open_hearing) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: [create(:case_hearing, hearing_disp: nil)]
      )
    end
    let!(:case_with_two_closed_hearings) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: create_list(:case_hearing, 2, hearing_disp: "H")
      )
    end
    let!(:case_with_two_open_hearings) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: create_list(:case_hearing, 2, hearing_disp: nil)
      )
    end

    it "excludes cases that have open hearings" do
      expect(described_class.cases_that_need_hearings).to match_array(
        [
          case_without_hearing, case_with_closed_hearing, case_with_two_closed_hearings
        ]
      )
    end
  end
end
