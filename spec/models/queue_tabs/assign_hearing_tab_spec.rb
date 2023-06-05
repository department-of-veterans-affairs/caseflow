# frozen_string_literal: true

describe AssignHearingTab do
  let(:regional_office_key) { "RO18" }
  let(:cache_ama_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }
  let(:cache_legacy_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

  describe ".tasks" do
    context "Legacy Appeal cases" do
      let(:number_of_cases) { 10 }

      context "when there are no cases CO hearings" do
        let(:params) do
          {
            appeal_type: LegacyAppeal.name,
            regional_office_key: regional_office_key
          }
        end
        let!(:cases) do
          create_list(:case, number_of_cases,
                      bfregoff: regional_office_key,
                      bfhr: "2",
                      bfcurloc: "57",
                      bfdocind: HearingDay::REQUEST_TYPES[:video])
        end

        let!(:c_number_case) do
          create(
            :case,
            bfcorlid: "1234C",
            bfregoff: regional_office_key,
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
          HearingTaskTreeInitializer.create_schedule_hearing_tasks.each do |appeal|
            appeal.update(closest_regional_office: regional_office_key)
          end

          cache_legacy_appeals
        end

        it "returns tasks for all relevant appeals in location 57" do
          tasks = AssignHearingTab.new(appeal_type: LegacyAppeal.name, regional_office_key: regional_office_key).tasks
          expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(
            cases.pluck(:bfkey) + [c_number_case.bfkey]
          )
        end
      end

      context "when there are cases with central office hearings" do
        let!(:cases) do
          create_list(:case, number_of_cases,
                      bfregoff: regional_office_key,
                      bfhr: "1",
                      bfcurloc: "57",
                      bfdocind: HearingDay::REQUEST_TYPES[:central])
        end

        let!(:video_cases) do
          create_list(:case, number_of_cases,
                      bfregoff: regional_office_key,
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
          HearingTaskTreeInitializer.create_schedule_hearing_tasks.each do |appeal|
            appeal.update(closest_regional_office: regional_office_key)
          end

          cache_legacy_appeals
        end

        it "returns tasks for all CO hearings in location 57" do
          tasks = AssignHearingTab.new(appeal_type: LegacyAppeal.name, regional_office_key: "C").tasks
          expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey))
        end

        it "does not return tasks for regional office when marked as CO" do
          HearingTaskTreeInitializer.create_schedule_hearing_tasks
          cache_legacy_appeals

          tasks = AssignHearingTab.new(appeal_type: LegacyAppeal.name, regional_office_key: regional_office_key).tasks
          expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(video_cases.pluck(:bfkey))
        end
      end
    end

    context "AMA cases" do
      let(:veteran_at_ro) { create(:veteran) }
      let(:appeal_for_veteran_at_ro) do
        create(:appeal, veteran: veteran_at_ro, closest_regional_office: regional_office_key)
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
        cache_ama_appeals
        tasks = AssignHearingTab.new(appeal_type: Appeal.name, regional_office_key: regional_office_key).tasks

        expect(tasks.count).to eq(1)
        expect(tasks[0].id).to eq(schedule_hearing_task.id)
      end
    end
  end

  context "AMA appeals" do
    let(:tab) { AssignHearingTab.new(params) }
    let(:assignee) { HearingsManagement.singleton }
    let(:params) do
      {
        appeal_type: Appeal.name,
        regional_office_key: regional_office_key
      }
    end
    let(:appeal) do
      create(
        :appeal,
        closest_regional_office: regional_office_key
      )
    end

    let!(:hearing_location1) do
      create(
        :available_hearing_locations,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        city: "New York",
        state: "NY",
        facility_id: "vba_372",
        facility_type: "va_benefits_facility",
        distance: 9
      )
    end

    let!(:hearing_location2) do
      create(
        :available_hearing_locations,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        city: "San Francisco",
        state: "CA",
        distance: 100
      )
    end

    let!(:task1) { create(:schedule_hearing_task, assigned_to: assignee, appeal: appeal) }
    let!(:task2) { create(:schedule_hearing_task, assigned_to: assignee, appeal: appeal) }

    describe ".power_of_attorney_name_options" do
      before do
        create(
          :bgs_power_of_attorney,
          :with_name_cached,
          appeal: appeal,
          claimant_participant_id: appeal.claimant.participant_id
        )
      end

      subject { tab.power_of_attorney_name_options }

      it "returns correct options" do
        cache_ama_appeals

        expect(subject.first[:value]).to eq(URI.escape(URI.escape(appeal.representative_name)))
        expect(subject.first[:displayText]).to eq("#{appeal.representative_name} (2)")
      end
    end

    describe ".suggested_location_options" do
      subject { tab.suggested_location_options }

      it "returns correct options" do
        cache_ama_appeals

        expect(subject.first[:value]).to eq(URI.escape(URI.escape(hearing_location1.formatted_location)))
        expect(subject.first[:displayText]).to eq("#{hearing_location1.formatted_location} (2)")
      end
    end

    describe ".columns" do
      subject { tab.columns }

      it "returns columns with the correct keys" do
        expect(subject.first.keys).to match_array([:name, :filter_options])
      end
    end

    describe ".to_hash" do
      subject { tab.to_hash }

      it "returns a hash with the correct key" do
        expect(subject.keys).to match_array([:columns])
      end
    end
  end
end
