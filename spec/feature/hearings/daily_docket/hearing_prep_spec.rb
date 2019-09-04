# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket for Hearing Prep", :all_dbs do
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }
  let!(:hearing_day) { create(:hearing_day, judge: current_user) }

  context "with a legacy hearing" do
    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: current_user, hearing_day: hearing_day) }

    scenario "User can update hearing prep fields" do
      visit "hearings/schedule/docket/" + legacy_hearing.hearing_day.id.to_s

      expect(page).to have_button("Print all Hearing Worksheets", disabled: false)
      click_dropdown(name: "#{legacy_hearing.external_id}-disposition", index: 0)
      click_button("Confirm")
      expect(page).to have_content("You have successfully updated")

      click_dropdown(name: "#{legacy_hearing.external_id}-aod", text: "Granted")
      click_dropdown(name: "#{legacy_hearing.external_id}-holdOpen", index: 0)
      find("label", text: "Transcript Requested", match: :first).click
      find("textarea", id: "#{legacy_hearing.external_id}-notes", match: :first)
        .fill_in(with: "This is a note about the hearing!")
      click_button("Save", match: :first)

      expect(page).to have_content("You have successfully updated")
    end
  end
end
