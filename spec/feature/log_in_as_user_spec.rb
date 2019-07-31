# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

RSpec.feature "Log in as User", :postgres do
  before do
    User.create(station_id: "283", css_id: "ANNE MERICA")
    User.authenticate!
  end

  after do
    User.unauthenticate!
  end

  scenario "Non authorized user will not see the feature" do
    visit "test/users"
    expect(page).to have_content("DSUSER")
    expect(page).not_to have_content("Log in as user")
  end

  context "user is Global Admin" do
    before do
      Functions.grant!("Global Admin", users: ["DSUSER"])
    end

    after do
      Functions.client.del("Global Admin")
    end

    scenario "user is able to log in as user" do
      visit "test/users"
      fill_in "User ID", with: "ANNE MERICA"
      fill_in "Station ID", with: "283"
      safe_click("#button-Log-in-as-user")
      expect(page).to have_content("ANNE MERICA (DSUSER)")
      expect(page).to have_content("Certification Help")

      visit "test/users"
      expect(page).not_to have_content("Log in as user")

      find("a", text: "ANNE MERICA (DSUSER)").click
      find("a", text: "Sign Out").click
      expect(page).to have_content("DSUSER")
      expect(page).to have_content("admin page")
    end
  end

  scenario "User visits session page" do
    visit "test/users/me"

    expect(page).to have_content("Your session")
    expect(page).to have_content("session_id")
  end
end
