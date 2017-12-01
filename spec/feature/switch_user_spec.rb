require "rails_helper"

RSpec.feature "Test Users for Demo" do
  before do
    # Switch user only works in demo
    ENV["DEPLOY_ENV"] = "demo"
    BGSService.end_product_data = BGSService.all_grants

    User.create(station_id: "283", css_id: User::FUNCTIONS.sample)
    User.create(station_id: "ABC", css_id: User::FUNCTIONS.sample)
    User.create(station_id: "283", css_id: "ANNE MERICA")
    User.authenticate!
  end

  scenario "We can switch between users in the database in demo mode" do
    visit "test/users"
    expect(page).not_to have_content("123 (DSUSER)")
    expect(page).to have_content("DSUSER")
    page.first(:xpath, "//div[@class='Select-control']").click
    page.first(:xpath, "//div[@id='react-select-2--option-0']").click
    page.first(:xpath, "//button[@id='button-Switch-user']").click
    expect(page).not_to have_content("123 (DSUSER)")
  end

  # Dispatch-speific seeding
  scenario "We can switch between test EP data in demo mode" do
    visit "test/users"
    page.first(:xpath, "//button[@id='main-tab-1']").click
    page.first(:xpath, "//button[@id='button-Seed-all-grants']").click
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "070"))
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "071"))
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "072"))
  end
end
