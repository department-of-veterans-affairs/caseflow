# frozen_string_literal: true

RSpec.feature "Test Users for Demo", :postgres do
  before do
    # Switch user only works in demo
    ENV["DEPLOY_ENV"] = "development"
    BGSService.end_product_records = { default: BGSService.all_grants }

    3.times { create(:user) }
    User.authenticate! # creates the DSUSER account
  end

  scenario "We can switch between users in the database in demo mode" do
    visit "test/users"
    expect(page.has_no_content?("123 (DSUSER)")).to eq(true)
    expect(page).to have_content("DSUSER")
    safe_click("div.cf-select__control")
    safe_click("#react-select-2-option-0")
    safe_click("#button-Switch-user")
    expect(page.has_no_content?("123 (DSUSER)")).to eq(true)
  end

  # Dispatch-speific seeding
  scenario "We can switch between test EP data in demo mode" do
    visit "test/users"
    safe_click("#main-tab-2")
    safe_click("#button-Seed-all-grants")
    expect(BGSService.end_product_records[:default]).to include(hash_including(end_product_type_code: "070"))
    expect(BGSService.end_product_records[:default]).to include(hash_including(end_product_type_code: "071"))
    expect(BGSService.end_product_records[:default]).to include(hash_including(end_product_type_code: "072"))
  end
end
