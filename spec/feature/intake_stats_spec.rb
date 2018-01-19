require "rails_helper"

RSpec.feature "Certification Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 7, 17, 55, 0, rand(1000)))
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["System Admin"])

    RampElection.create!(veteran_file_number: "77776661", notice_date: 1.day.ago)
    RampElection.create!(veteran_file_number: "77776662", notice_date: 1.day.ago)
    RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 7.days.ago,
      receipt_date: 45.minutes.ago,
      end_product_reference_id: "132"
    )

    visit "/intake/stats"
    expect(page).to have_content("RAMP Elections for January (so far)")
    expect(page).to have_content("Sent 2")
    expect(page).to have_content("Successfully Received 1")
    expect(page).to have_content("Average Response Time 7.00 days")

    click_on "Daily"
    expect(page).to have_content("RAMP Elections for January 7")
    expect(page).to have_content("Sent 0")
    expect(page).to have_content("Successfully Received 1")
    expect(page).to have_content("Average Response Time 7.00 days")
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/stats"
    expect(page).to have_content("You aren't authorized")
  end
end
