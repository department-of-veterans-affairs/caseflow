# frozen_string_literal: true

describe HearingCoordinatorScheduleQueue, :all_dbs do
  describe "#tasks" do
    let(:user) { create(:user) }
    let(:regional_office) { "RO17" }
    let(:number_of_cases) { 10 }

    context "when there are no cases CO hearings" do
      let!(:cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "2",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:video])
      end

      let!(:c_number_case) do
        create(
          :case,
          bfcorlid: "1234C",
          bfregoff: regional_office,
          bfhr: "2",
          bfcurloc: 57,
          bfdocind: HearingDay::REQUEST_TYPES[:video]
        )
      end

      let!(:veterans) do
        VACOLS::Case.all.map do |vacols_case|
          create(
            :veteran,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      let!(:non_hearing_cases) do
        create_list(:case, number_of_cases)
      end

      before do
        AppealRepository.create_schedule_hearing_tasks.each do |appeal|
          appeal.update(closest_regional_office: regional_office)
        end
      end

      it "returns tasks for all relevant appeals in location 57" do
        tasks = HearingCoordinatorScheduleQueue.new(user, regional_office: regional_office).tasks

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey) + [c_number_case.bfkey])
      end
    end

    context "when there are cases with central office hearings" do
      let!(:cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "1",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:central])
      end

      let!(:video_cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "2",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:video])
      end

      let!(:veterans) do
        VACOLS::Case.all.map do |vacols_case|
          create(
            :veteran,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      before do
        AppealRepository.create_schedule_hearing_tasks.each do |appeal|
          appeal.update(closest_regional_office: regional_office)
        end
      end

      it "returns tasks for all CO hearings in location 57" do
        tasks = HearingCoordinatorScheduleQueue.new(user, regional_office: "C").tasks

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey))
      end

      it "does not return tasks for regional office when marked as CO" do
        AppealRepository.create_schedule_hearing_tasks

        tasks = HearingCoordinatorScheduleQueue.new(user, regional_office: regional_office).tasks

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(video_cases.pluck(:bfkey))
      end
    end

    context "when there are AMA ScheduleHearingTasks" do
      let(:veteran_at_ro) { create(:veteran) }
      let(:appeal_for_veteran_at_ro) do
        create(:appeal, veteran: veteran_at_ro, closest_regional_office: regional_office)
      end
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal_for_veteran_at_ro) }

      let(:veteran_at_different_ro) { create(:veteran) }
      let(:appeal_for_veteran_at_different_ro) do
        create(:appeal, veteran: veteran_at_different_ro, closest_regional_office: "RO04")
      end
      let!(:hearing_task_for_other_veteran) do
        create(:schedule_hearing_task, appeal: appeal_for_veteran_at_different_ro)
      end

      it "returns tasks for all appeals associated with Veterans at regional office" do
        tasks = HearingCoordinatorScheduleQueue.new(user, regional_office: regional_office).tasks

        expect(tasks.count).to eq(1)
        expect(tasks[0].id).to eq(schedule_hearing_task.id)
      end
    end
  end
end
