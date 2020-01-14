# frozen_string_literal: true

RSpec.feature "Dispatch Stats Dashboard", :postgres, skip: "deprecated" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 55, 0, rand(1000)))
  end

  context ".show#daily" do
    before do
      Rails.cache.clear
      DispatchStats.calculate_all!
    end
    it "switches between the tabs" do
      User.authenticate!(roles: ["Manage Claim Establishment"])
      visit "/dispatch/stats"
      expect(page).to have_content("Establish Claim Tasks Identified")
      expect(page).to have_content("Establish Claim Task Activity")
      expect(page).to have_content("Establish Claim Task Completion Rate")
      expect(page).to have_content("Time to Claim Establishment")
      expect(page).to have_content("Establish Claim Tasks Canceled")

      click_on "Daily"
      expect(page).to have_content("Establish Claim Tasks Identified")
    end
  end

  context ".show" do
    before do
      Generators::EstablishClaim.create(started_at: 30.minutes.ago, completed_at: 15.minutes.ago, completion_status: 0)
      Generators::EstablishClaim.create(started_at: 30.minutes.ago)
      Rails.cache.clear
      DispatchStats.calculate_all!
    end
    it "loads the correct stats" do
      User.authenticate!(roles: ["Manage Claim Establishment"])
      visit "/dispatch/stats"
      expect(page).to have_content("All\n2")
    end
  end

  scenario "Users without manager permissions cannot view page" do
    User.authenticate!
    visit "/dispatch/stats"
    expect(page).to have_content("Drat!\nYou aren't authorized to use this part of Caseflow yet.")
  end
end
