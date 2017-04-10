require "rails_helper"

RSpec.feature "Dispatch Stats Dashboard", focus: true do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 55, 0, rand(1000)))
    DispatchStats.calculate_all!

    # Necessary role to view dispatch_stats page
    User.authenticate!(roles: ["Manage Claim Establishment"])
  end

  scenario "Page loads correctly with tabs" do
    visit "/dispatch/stats"
    expect(page).to have_content("Establish Claim Tasks Identified for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Task Activity for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Task Completion Rate for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Time to Claim Establishment for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Tasks Canceled for 12:00–12:59 EST (so far)")

    click_on "Daily"
    expect(page).to have_content("Establish Claim Tasks Identified for January 1 (so far)")
  end
end
