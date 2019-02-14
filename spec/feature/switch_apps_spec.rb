require "rails_helper"

RSpec.feature "SwitchApps" do
  context "A user with just Queue access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader"]))
    end

    scenario "doesn't see switch product dropdown" do
      visit "/queue"

      expect(page).to have_content("Queue")
      expect(page).to_not have_content("Switch product")
    end
  end

  context "A user with Queue and Hearing Schedule access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader", "Build HearSched"]))
    end

    scenario "sees switch product dropdown and can navigate to hearing schedule" do
      visit "/queue"

      expect(page).to have_content("Queue")

      find("a", text: "Switch product").click
      find("a", text: "Caseflow Hearing Schedule").click

      expect(page).to have_content("Welcome to Hearing Schedule!")
    end
  end
end
