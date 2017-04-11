require "rails_helper"

RSpec.feature "Dispatch Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 55, 0, rand(1000)))
    DispatchStats.calculate_all!
  end

  scenario "Page loads correctly with tabs" do
    User.authenticate!(roles: ["Manage Claim Establishment"])
    visit "/dispatch/stats"
    expect(page).to have_content("Establish Claim Tasks Identified for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Task Activity for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Task Completion Rate for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Time to Claim Establishment for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Establish Claim Tasks Canceled for 12:00–12:59 EST (so far)")

    click_on "Daily"
    expect(page).to have_content("Establish Claim Tasks Identified for January 1 (so far)")
  end

  scenario "Users without manager permissions cannot view page" do
    User.authenticate!
    visit "/dispatch/stats"
    expect(page).to have_content("Drat! You aren't authorized to use this part of Caseflow yet.")
  end
end
