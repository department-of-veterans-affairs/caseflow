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
end
