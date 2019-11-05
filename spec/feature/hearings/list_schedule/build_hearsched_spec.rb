# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "List Schedule for Build HearSched", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  context "Correct buttons are displayed" do
    let!(:hearing) { create(:hearing) }

    scenario "All buttons are visible" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      expect(page).to have_content("Schedule Veterans")
      expect(page).to have_content("Build Schedule")
      expect(page).to have_content("Add Hearing Date")
    end
  end

  context "Schedule with a Virtual Hearing" do
    let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO42") }
    let!(:virtual_hearing) { create(:virtual_hearing, :active, hearing: hearing) }

    scenario "Shows the 'Video, Virtual' request type" do
      visit("hearings/schedule")

      expect(page).to have_content("Video, Virtual")
    end
  end
end
