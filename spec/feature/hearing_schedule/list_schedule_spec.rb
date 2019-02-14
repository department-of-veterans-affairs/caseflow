require "rails_helper"

RSpec.feature "List Schedule" do
  context "Correct buttons are displayed based on permissions" do
    let!(:hearing) { create(:hearing) }

    context "Build hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

      scenario "Buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content("Schedule Veterans")
        expect(page).to have_content("Build Schedule")
        expect(page).to have_content("Add Hearing Date")
      end
    end

    context "Edit hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Edit HearSched"]) }

      scenario "Buttons are not visible" do
        visit "hearings/schedule"

        expect(page).to have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end
  end
end
