# frozen_string_literal: true

describe HearingTaskTreeInitializer do
  context "#for_appeal_with_pending_travel_board_hearing" do
    let(:vacols_case) do
      create(
        :case,
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        bfhr: "2"
      )
    end
    let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    subject { described_class.for_appeal_with_pending_travel_board_hearing(appeal) }

    context "the task tree does not already exist" do
      it "it creates the expected tasks" do
        expect(ChangeHearingRequestTypeTask.count).to eq(0)
        expect(ScheduleHearingTask.count).to eq(0)
        expect(HearingTask.count).to eq(0)
        subject
        expect(ChangeHearingRequestTypeTask.count).to eq(1)
        expect(ScheduleHearingTask.count).to eq(1)
        expect(HearingTask.count).to eq(1)
      end

      it "creates tasks that are all assigned to BVA" do
        subject
        expect(
          appeal
            .tasks
            .reject { |task| task.is_a?(RootTask) }
            .all? { |task| task.assigned_to == Bva.singleton }
        ).to eq(true)
      end
    end

    context "there's a closed hearing task on the appeal" do
      let(:root_task) { create(:root_task, appeal: appeal) }
      let!(:hearing_task) do
        create(:hearing_task, appeal: appeal, parent: root_task)
      end

      before do
        hearing_task.update!(status: Constants.TASK_STATUSES.completed)
      end

      it "creates a new hearing task parent" do
        expect(HearingTask.count).to eq(1)
        subject
        expect(ChangeHearingRequestTypeTask.count).to eq(1)
        expect(ScheduleHearingTask.count).to eq(1)
        expect(HearingTask.count).to eq(2)
      end
    end
  end

  context "#create_schedule_hearing_tasks" do
    context "when missing legacy appeals" do
      let!(:cases) { create_list(:case, 10, bfcurloc: "57", bfhr: "1") }

      it "creates the legacy appeal and creates schedule hearing tasks" do
        described_class.create_schedule_hearing_tasks

        expect(LegacyAppeal.all.pluck(:vacols_id)).to match_array(cases.pluck(:bfkey))
        expect(ScheduleHearingTask.all.pluck(:appeal_id)).to match_array(LegacyAppeal.all.pluck(:id))
        expect(ScheduleHearingTask.first.parent.type).to eq(HearingTask.name)
        expect(ScheduleHearingTask.first.parent.parent.type).to eq(RootTask.name)
        expect(cases.map { |vcase| vcase.reload.bfcurloc }.uniq).to eq([LegacyAppeal::LOCATION_CODES[:caseflow]])
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
        case_hearings: [create(:case_hearing, hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held])]
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
        case_hearings: create_list(
          :case_hearing,
          2,
          hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held]
        )
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
