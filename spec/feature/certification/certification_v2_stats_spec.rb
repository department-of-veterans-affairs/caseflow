require "rails_helper"

RSpec.feature "CertificationV2 Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 55, 0, rand(1000)))

    Certification.create(
      created_at:          10.hours.ago,
      completed_at:        5.hours.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          9.hours.ago,
      completed_at:        5.hours.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          8.hours.ago,
      completed_at:        5.hours.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          210.minutes.ago,
      completed_at:        120.minutes.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          45.minutes.ago,
      completed_at:        15.minutes.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          45.minutes.ago,
      completed_at:        30.minutes.ago,
      v2:                  true
    )

    Certification.create(
      created_at:          7.hours.ago,
      completed_at:        nil,
      v2:                  true
    )

    Certification.create(
      created_at:          5.hours.ago,
      completed_at:        nil,
      v2:                  true
    )

    Certification.create(
      created_at:          5.hours.ago,
      completed_at:        4.hours.ago
    )

    Certification.create(
      created_at:          45.minutes.ago,
      completed_at:        30.minutes.ago
    )

    CertificationV2Stats.calculate_all!

    # Necessary role to view certification_stats page
    User.authenticate!(roles: ["System Admin"])
  end

  let(:leftarrow) { "d3.select(window).dispatch('keydown', { detail: { keyCode: 37 } })" }
  let(:rightarrow) { "d3.select(window).dispatch('keydown', { detail: { keyCode: 39 } })" }

  scenario "Switching tab intervals" do
    visit "/certification_v2/stats"
    expect(page).to have_content("Activity for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Certifications Started 2")
    expect(page).to have_content("Certifications Completed 2")
    expect(page).to have_content("Overall 100 %")
    # # TODO: When #101 in caseflow-commons is fixed median should be changed to 22.50
    expect(page).to have_content("Overall (median) 30.00 min")
    click_on "Daily"
    expect(page).to have_content("Activity for January 1 (so far)")
    expect(page).to have_content("Certifications Started 8")
    expect(page).to have_content("Certifications Completed 6")
    expect(page).to have_content("Overall 75 %")
    # TODO: When #101 in caseflow-commons is fixed median should be changed to 2.50
    expect(page).to have_content("Overall (median) 3.00 hours")
  end

  scenario "Toggle median to 95th percentile and navigate to past periods" do
    visit "/certification/stats"

    # Turn mouseover events off on the Stats dashboard to not confuse Chrome
    page.execute_script("window.Dashboard.mouseoverEvents = false;")

    click_on "Daily"
    find("#time-to-certify-toggle").click
    expect(page).to have_content("Overall (95th percentile)")
    expect(page).to have_content("December 17")
    # Scroll once more to see December 16 have no stats
    page.driver.execute_script(leftarrow)
    expect(page).to have_content("December 16")
    expect(page).to have_content("Overall (95th percentile)")
    find("#time-to-certify-toggle").click
    # Scroll to the most recent time interval
    page.driver.execute_script(rightarrow)
    expect(page).to have_content("Overall (median)")
  end

  scenario "Unauthorized user access" do
    # Unauthenticated access
    User.unauthenticate!
    visit "/certification_v2/stats"
    expect(page).not_to have_content("Activity for")
    expect(page).not_to have_content("Certification Rate")
    expect(page).not_to have_content("Time to Certify")

    # Authenticated access with System Admin CSS role
    User.tester!(roles: ["System Admin"])
    visit "/certification/stats"
    expect(page).not_to have_content("Activity for")
    expect(page).not_to have_content("Certification Rate")
    expect(page).not_to have_content("Time to Certify")
    expect(page).not_to have_content("Missing Documents")

    # Authenticated access without System Admin role
    User.authenticate!
    visit "/certification_v2/stats"
    expect(page).not_to have_content("Activity for")
    expect(page).not_to have_content("Certification Rate")
    expect(page).not_to have_content("Time to Certify")

    expect(page).to have_content("You aren't authorized to use this part of Caseflow yet.")
    expect(page).to have_content("Unauthorized")
  end
end
