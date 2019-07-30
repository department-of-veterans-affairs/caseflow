# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

RSpec.feature "Dropdown", :postgres do
  scenario "Dropdown works on both erb and react pages" do
    User.authenticate!

    visit "test/users"
    find("a", text: "DSUSER (DSUSER)").click
    expect(page).to have_content("Sign Out")

    visit "dispatch/establish-claim"
    find("a", text: "Menu") .click
    expect(page).to have_content("Help")
  end
end
