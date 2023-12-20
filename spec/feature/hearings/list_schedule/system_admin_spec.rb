# frozen_string_literal: true

RSpec.feature "List Schedule for System Admin", :all_dbs do
  let!(:current_user) { User.authenticate!(roles: ["System Admin"]) }

  context "Correct buttons are displayed" do
    let!(:hearing) { create(:hearing) }
    let!(:hearing_day) { create(:hearing_day) }

    scenario "Correct days are displayed" do
      visit "hearings/schedule"

      expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
    end

    scenario "All buttons are visible" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_JUDGE_DEFAULT_VIEW_PAGE_HEADER)
      expect(page).to have_content("Schedule Veterans")
      expect(page).to have_content("Build Schedule")
      expect(page).to have_content("Add Hearing Day")
    end
  end
end
