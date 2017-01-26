require "rails_helper"

RSpec.feature "Switch User" do
  before do
    # Switch user only works in demo deploy env
    ENV["DEPLOY_ENV"] = "dev"

    User.create(station_id: "283", css_id: "123")
    User.create(station_id: "ABC", css_id: "456")
    User.create(station_id: "283", css_id: "ANNE MERICA")
  end

  scenario "We can switch between users in the database in dev mode" do
    visit "test/users"
    expect(page).not_to have_content("123 (DSUSER)")
    expect(page).to have_content("123")
    click_on "123"
    expect(page).to have_content("123 (DSUSER)")
  end
end
