# frozen_string_literal: true

##
# Tests various aspects of the state of `schedule/assign` page, mostly focusing on table
RSpec.feature "Assign Hearings Table" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    User.authenticate!(user: user)
  end

  let(:cache_legacy_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }
  let(:cache_ama_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

  before do
    HearingsManagement.singleton.add_user(current_user)
    HearingAdmin.singleton.add_user(current_user)
  end

  context "No upcoming hearing days" do
    scenario "Show status message for empty upcoming hearing days" do
      visit "hearings/schedule/assign"
      click_dropdown(text: "Winston-Salem, NC")
      expect(page).to have_content("No upcoming hearing days")
    end
  end

  context "When list of veterans displays in Legacy Veterans Waiting" do
    let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 30) }
    let!(:schedule_hearing_task1) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case, :central_office_hearing,
            :type_cavc_remand,
            bfcorlid: "123454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "91",
              tinum: "1545678",
              titrnum: "123454787S"
            )
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran1) { create(:veteran, file_number: "123454787") }
    let!(:schedule_hearing_task2) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :aod,
            :type_original,
            bfcorlid: "123454788S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "92",
              tinum: "1645621",
              titrnum: "123454788S"
            )
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran2) { create(:veteran, file_number: "123454788") }
    let!(:schedule_hearing_task3) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :aod,
            :type_original,
            bfcorlid: "323454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "93",
              tinum: "1645678",
              titrnum: "323454787S"
            )
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran3) { create(:veteran, file_number: "323454787") }
    let!(:schedule_hearing_task4) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :type_original,
            bfcorlid: "123454789S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "94",
              tinum: "1445678",
              titrnum: "123454789S"
            )
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran4) { create(:veteran, file_number: "123454789") }
    let!(:schedule_hearing_task5) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :type_original,
            bfcorlid: "523454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "95",
              tinum: "1445695",
              titrnum: "523454787S"
            )
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran5) { create(:veteran, file_number: "523454787") }

    scenario "Verify docket order is CVAC, AOD, then regular." do
      cache_legacy_appeals
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Central")
      click_button("Legacy Veterans Waiting", exact: true)
      table_row = page.find("tr", id: "table-row-0")
      expect(table_row).to have_content("1545678", wait: 30)
      table_row = page.find("tr", id: "table-row-1")
      expect(table_row).to have_content("1645621")
      table_row = page.find("tr", id: "table-row-2")
      expect(table_row).to have_content("1645678")
      table_row = page.find("tr", id: "table-row-3")
      expect(table_row).to have_content("1445678")
      table_row = page.find("tr", id: "table-row-4")
      expect(table_row).to have_content("1445695")
    end
  end

  context "Pagination" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 60.days,
        regional_office: "RO39"
      )
    end

    let(:unassigned_count) { 3 }
    let(:regional_office) { "RO39" }
    let(:default_cases_per_page) { TaskPager::TASKS_PER_PAGE }

    def create_ama_appeals
      appeal_one = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 1)
      )
      AvailableHearingLocations.create(
        appeal: appeal_one,
        city: "Los Angeles",
        state: "CA",
        distance: 89,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal_one,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal_one,
        city: "San Francisco",
        state: "CA",
        distance: 76,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )

      appeal_two = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 2)
      )
      AvailableHearingLocations.create(
        appeal: appeal_two,
        city: "Los Angeles",
        state: "CA",
        distance: 23,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal_two,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal_two,
        city: "San Francisco",
        state: "CA",
        distance: 76,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )

      appeal_three = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 3)
      )
      AvailableHearingLocations.create(
        appeal: appeal_three,
        city: "Los Angeles",
        state: "CA",
        distance: 89,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal_three,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal_three,
        city: "San Francisco",
        state: "CA",
        distance: 13,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )
      create(:schedule_hearing_task, appeal: appeal_one)
      create(:schedule_hearing_task, appeal: appeal_two)
      create(:schedule_hearing_task, appeal: appeal_three)
    end

    def create_cached_poas
      Appeal.all.each_with_index do |appeal, idx|
        create(
          :bgs_power_of_attorney,
          :with_name_cached,
          appeal: appeal,
          claimant_participant_id: appeal.claimant.participant_id,
          representative_name: "Attorney #{idx}"
        )
      end
    end

    def navigate_to_ama_tab
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
      expect(page).to have_content("AMA Veterans Waiting")
      click_button("AMA Veterans Waiting", exact: true)
    end

    context "Specify page number" do
      let(:unassigned_count) { default_cases_per_page + 5 }
      let(:page_no) { 2 }
      let(:query_string) do
        "#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}="\
        "#{Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}"\
        "&regional_office_key=#{regional_office}"\
        "&#{Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM}=#{page_no}"
      end

      it "shows correct number of tasks" do
        20.times do
          appeal = create(:appeal, closest_regional_office: "RO39")
          create(:schedule_hearing_task, appeal: appeal)
        end
        cache_ama_appeals

        visit "hearings/schedule/assign/?#{query_string}"

        expect(page).to have_content(
          "Viewing #{default_cases_per_page + 1}-#{unassigned_count} of #{unassigned_count} total"
        )
        page.find_all(".cf-current-page").each { |btn| expect(btn).to have_content(page_no) }
        expect(find("tbody").find_all("tr").length).to eq(unassigned_count - default_cases_per_page)
      end
    end

    context "Filter by SuggestedHearingLocation column" do
      before do
        create_ama_appeals
        cache_ama_appeals
        navigate_to_ama_tab
      end

      it "filters are correct, and filter as expected" do
        step "check if there are the right number of rows for the ama tab" do
          expect(page).to have_content("Suggested Location")
          expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
        end

        step "check if the filter options are as expected" do
          expect(page).to have_content("Suggested Location")
          expect(page).to have_selector(".unselected-filter-icon-inner", count: 3)
          page.find_all(".unselected-filter-icon-inner")[1].click
          expect(page).to have_content("#{Appeal.first.suggested_hearing_location.formatted_location} (1)")
          expect(page).to have_content("#{Appeal.second.suggested_hearing_location.formatted_location} (1)")
          expect(page).to have_content("#{Appeal.third.suggested_hearing_location.formatted_location} (1)")
        end

        step "clicking on a filter reduces the number of results by the expect amount" do
          page.find(
            "label",
            text: "#{Appeal.first.suggested_hearing_location.formatted_location} (1)",
            match: :prefer_exact
          ).click
          expect(find("tbody").find_all("tr").length).to eq(1)
        end
      end
    end

    context "Filter by PowerOfAttorneyName column" do
      before do
        create_ama_appeals
        create_cached_poas
        cache_ama_appeals
        navigate_to_ama_tab
      end

      it "filters are correct, and filter as expected" do
        step "check if there are the right number of rows for the ama tab" do
          expect(page).to have_content("Power of Attorney (POA)")
          expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
        end

        step "check if the filter options are as expected" do
          expect(page).to have_content("Power of Attorney (POA)")
          expect(page).to have_selector(".unselected-filter-icon-inner", count: 3)
          page.find_all(".unselected-filter-icon-inner").last.click
          expect(page).to have_content("#{Appeal.first.representative_name} (1)")
          expect(page).to have_content("#{Appeal.second.representative_name} (1)")
          expect(page).to have_content("#{Appeal.third.representative_name} (1)")
        end

        step "clicking on a filter reduces the number of results by the expect amount" do
          page.find("label", text: "#{Appeal.first.representative_name} (1)", match: :prefer_exact).click
          expect(find("tbody").find_all("tr").length).to eq(1)
        end
      end
    end
  end

  context "Hearing Request Type column" do
    let(:closest_regional_office) { "RO17" } # St. Petersburg
    let!(:hearing_day) do # video hearing day
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        regional_office: closest_regional_office,
        scheduled_for: Time.zone.today + 30
      )
    end

    context "Legacy Veterans waiting queue" do
      let!(:schedule_hearing_task1) do # video hearing request type, CAVC
        create(
          :schedule_hearing_task,
          appeal: create(
            :legacy_appeal,
            vacols_case: create(
              :case,
              :video_hearing_requested,
              :travel_board_hearing,
              folder: create(:folder, tinum: "1") # docket number
            ),
            closest_regional_office: closest_regional_office
          )
        )
      end
      let!(:schedule_hearing_task2) do # travel hearing request type
        create(
          :schedule_hearing_task,
          appeal: create(
            :legacy_appeal,
            vacols_case: create(
              :case,
              :travel_board_hearing,
              folder: create(:folder, tinum: "2") # docket number
            ),
            closest_regional_office: closest_regional_office
          )
        )
      end
      let!(:schedule_hearing_task3) do # former travel, now virtual
        create(
          :schedule_hearing_task,
          appeal: create(
            :legacy_appeal,
            vacols_case: create(
              :case,
              :travel_board_hearing,
              folder: create(:folder, tinum: "3") # docket number
            ),
            closest_regional_office: closest_regional_office,
            changed_hearing_request_type: HearingDay::REQUEST_TYPES[:virtual]
          )
        )
      end

      before { cache_legacy_appeals }

      scenario "Verify rows are populated correctly" do
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "St. Petersburg")
        click_button("Legacy Veterans Waiting", exact: true)
        expect(page).to have_content("Hearing Type")
        table_row = page.find("tr", id: "table-row-0")
        expect(table_row).to have_content("Video", wait: 30)
        table_row = page.find("tr", id: "table-row-1")
        expect(table_row).to have_content("Travel")
        table_row = page.find("tr", id: "table-row-2")
        expect(table_row).to have_content("former Travel, Virtual")
      end

      context "Filter by Hearing Type column" do
        it "filters are correct, and filter as expected" do
          step "navigate to St. Petersburg legacy veterans tab" do
            visit "hearings/schedule/assign"
            click_dropdown(text: "St. Petersburg")
            click_button("Legacy Veterans Waiting", exact: true)
          end

          step "check if the filter options are as expected" do
            expect(page).to have_content("Hearing Type")
            expect(page).to have_selector(".unselected-filter-icon-inner", count: 3)
            page.find_all(".unselected-filter-icon-inner").first.click
            expect(page).to have_content("Virtual (1)")
            expect(page).to have_content("Video (1)")
            expect(page).to have_content("former Travel (1)")
          end

          step "clicking on a filter reduces the number of results by the expect amount" do
            page.find("label", text: "former Travel (1)", match: :prefer_exact).click
            expect(find("tbody").find_all("tr").length).to eq(1)
          end
        end
      end
    end

    context "AMA Veterans waiting queue" do
      let!(:schedule_hearing_task1) do # Video
        create(:schedule_hearing_task, appeal: create(:appeal, closest_regional_office: closest_regional_office))
      end

      scenario "Verify rows are populated correctly" do
        cache_ama_appeals
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "St. Petersburg")
        click_button("AMA Veterans Waiting", exact: true)
        expect(page).to have_content("Hearing Type")
        table_row = page.find("tr", id: "table-row-0")
        expect(table_row).to have_content("Video")
      end
    end
  end
end
