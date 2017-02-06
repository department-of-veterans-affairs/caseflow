require "rails_helper"

RSpec.feature "Switch User" do
  before do
    # Switch user only works in demo deploy env
    ENV["DEPLOY_ENV"] = "dev"
    BGSService.end_product_data = BGSService.no_grants

    User.create(station_id: "283", css_id: "123")
    User.create(station_id: "ABC", css_id: "456")
    User.create(station_id: "283", css_id: "ANNE MERICA")
    User.authenticate!
  end

  scenario "We can switch between users in the database in dev mode" do
    visit "test/users"
    expect(page).not_to have_content("123 (DSUSER)")
    expect(page).to have_content("123")
    click_on "123"
    expect(page).to have_content("123 (DSUSER)")
  end

  # Note if this test ever fails non-deterministically it may be because
  # we check the updated data in BGSService before the server responds
  # to the request. Sync with mdbenjam to try and resolve it.
  scenario "We can switch between test EP data in dev mode" do
    visit "test/users"
    expect(page).to have_content("All Grants")
    click_on "All Grants"
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "170"))
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "171"))
    expect(BGSService.end_product_data).to include(hash_including(end_product_type_code: "172"))
  end
end
