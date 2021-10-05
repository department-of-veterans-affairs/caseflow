# frozen_string_literal: true

RSpec.feature "List Schedule for Build HearSched", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  context "Correct buttons are displayed" do
    let!(:hearing) { create(:hearing) }

    scenario "All buttons are visible" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      expect(page).to have_content("Schedule Veterans")
      expect(page).to have_content("Build Schedule")
      expect(page).to have_content("Add Hearing Day")
    end
  end

  context "Hearing Scheduled column" do
    let(:hearing_day_one) { create(:hearing_day) }
    let(:hearing_day_two) { create(:hearing_day) }
    let!(:hearings) do
      [
        create(:hearing, :held, hearing_day: hearing_day_one),
        create(:hearing, :cancelled, hearing_day: hearing_day_one),
        create(:hearing, :scheduled_in_error, hearing_day: hearing_day_two),
        create(:hearing, hearing_day: hearing_day_two), # nil disposition
        create(
          :legacy_hearing,
          hearing_day: hearing_day_one,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held]
        ),
        create(
          :legacy_hearing,
          hearing_day: hearing_day_one,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:scheduled_in_error]
        ),
        create(
          :legacy_hearing,
          hearing_day: hearing_day_two,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed]
        ),
        create(:legacy_hearing, hearing_day: hearing_day_two) # nil disposition
      ]
    end

    before do
      FeatureToggle.enable!(:view_and_download_hearing_scheduled_column)
    end

    scenario "Column displays with correct values" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      expect(page).to have_content("Hearings Scheduled")
      table_row = page.find("tr", id: "table-row-0")
      expect(table_row).to have_content("2")
      table_row = page.find("tr", id: "table-row-1")
      expect(table_row).to have_content("2")
    end
  end
end
