# frozen_string_literal: true

RSpec.feature "List Schedule for RO ViewHearSched", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["RO ViewHearSched"]) }

  context "Correct buttons are displayed based on permissions" do
    let!(:hearing) { create(:hearing) }

    scenario "No buttons are visible" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER_NONBOARD_USER)
      expect(page).to_not have_content("Schedule Veterans")
      expect(page).to_not have_content("Build Schedule")
      expect(page).to_not have_content("Add Hearing Day")
    end
  end
end
