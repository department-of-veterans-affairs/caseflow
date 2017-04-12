require "rails_helper"

RSpec.feature "Certification Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 55, 0, rand(1000)))

    Certification.create(
      nod_matching_at:     5.hours.ago,
      form9_matching_at:   5.hours.ago,
      soc_matching_at:     5.hours.ago,
      ssocs_required:      false,
      ssocs_matching_at:   nil,
      form8_started_at:    5.hours.ago,
      created_at:          5.hours.ago,
      completed_at:        4.hours.ago
    )

    Certification.create(
      nod_matching_at:     4.hours.ago,
      form9_matching_at:   5.hours.ago,
      soc_matching_at:     5.hours.ago,
      ssocs_required:      true,
      ssocs_matching_at:   4.hours.ago,
      form8_started_at:    4.hours.ago,
      created_at:          5.hours.ago,
      completed_at:        nil
    )

    Certification.create(
      nod_matching_at:     4.hours.ago,
      form9_matching_at:   5.hours.ago,
      soc_matching_at:     5.hours.ago,
      ssocs_required:      true,
      ssocs_matching_at:   5.hours.ago,
      form8_started_at:    4.hours.ago,
      created_at:          5.hours.ago,
      completed_at:        3.hours.ago
    )

    Certification.create(
      nod_matching_at:     45.minutes.ago,
      form9_matching_at:   45.minutes.ago,
      soc_matching_at:     45.minutes.ago,
      ssocs_required:      true,
      ssocs_matching_at:   45.minutes.ago,
      form8_started_at:    45.minutes.ago,
      created_at:          45.minutes.ago,
      completed_at:        30.minutes.ago
    )
    CertificationStats.calculate_all!

    # Necessary role to view certification_stats page
    User.authenticate!(roles: ["System Admin"])
  end

  let(:leftarrow) { "d3.select(window).dispatch('keydown', { detail: { keyCode: 37 } })" }
  let(:rightarrow) { "d3.select(window).dispatch('keydown', { detail: { keyCode: 39 } })" }

  scenario "Switching tab intervals" do
    visit "/certification/stats"
    expect(page).to have_content("Activity for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Certifications Started 1")
    expect(page).to have_content("Certifications Completed 1")
    expect(page).to have_content("Overall 100 %")
    expect(page).to have_content("Missing Document ?? %")
    expect(page).to have_content("Overall (median) 15.00 min")
    expect(page).to have_content("Missing Document (median) ??")
    expect(page).to have_content("Any Document 0 %")

    click_on "Daily"
    expect(page).to have_content("Activity for January 1 (so far)")
    expect(page).to have_content("Certifications Started 4")
    expect(page).to have_content("Certifications Completed 3")
    expect(page).to have_content("Overall 75 %")
    expect(page).to have_content("Missing Document 50 %")
    expect(page).to have_content("Overall (median) 60.00 min")
    expect(page).to have_content("Missing Document (median) 120.00 min")
    expect(page).to have_content("Any Document 50 %")
    expect(page).to have_content("NOD 50 %")
    expect(page).to have_content("SOC 0 %")
    expect(page).to have_content("SSOC 33 %")
    expect(page).to have_content("Form 9 0 %")
  end

  # The stats tests don't play well with Selenium Chrome
  # The mouseover effect with the stat bars is erratic
  # TODO: Augment stats to disable mouseover for the tests
  scenario "Check missing documents" do
    Certification.create(
      nod_matching_at:     45.minutes.ago,
      form9_matching_at:   45.minutes.ago,
      soc_matching_at:     45.minutes.ago,
      ssocs_required:      true,
      ssocs_matching_at:   43.minutes.ago,
      form8_started_at:    nil,
      created_at:          45.minutes.ago,
      completed_at:        nil
    )

    Certification.create(
      nod_matching_at:     45.minutes.ago,
      form9_matching_at:   45.minutes.ago,
      soc_matching_at:     nil,
      ssocs_required:      true,
      ssocs_matching_at:   45.minutes.ago,
      form8_started_at:    nil,
      created_at:          45.minutes.ago,
      completed_at:        nil
    )
    CertificationStats.calculate_all!

    visit "/certification/stats/daily"

    # Turn mousever events off on the Stats dashboard to not confuse Chrome
    page.execute_script("window.Dashboard.mouseoverEvents = false;")

    expect(page).to have_content("Activity for January 1 (so far)")
    expect(page).to have_content("Certifications Started 6")
    expect(page).to have_content("Certifications Completed 3")
    expect(page).to have_content("Overall 50 %")
    expect(page).to have_content("Missing Document 25 %")
    expect(page).to have_content("Overall (median) 60.00 min")
    expect(page).to have_content("Missing Document (median) 120.00 min")

    expect(page).to have_content("Any Document 67 %")
    expect(page).to have_content("NOD 33 %")
    expect(page).to have_content("SOC 17 %")
    expect(page).to have_content("SSOC 40 %")
    expect(page).to have_content("Form 9 0 %")
  end

  scenario "Toggle median to 95th percentile and navigate to past periods" do
    visit "/certification/stats"

    # Turn mousever events off on the Stats dashboard to not confuse Chrome
    page.execute_script("window.Dashboard.mouseoverEvents = false;")

    click_on "Daily"

    find("#time-to-certify-toggle").click

    expect(page).to have_content("Overall (95th percentile) 120.00 min")

    # Scroll once more to see December 31 have no stats
    page.driver.execute_script(leftarrow)
    expect(page).to have_content("December 31")
    expect(page).to have_content("Overall (95th percentile) ??")

    find("#time-to-certify-toggle").click

    # Scroll to the most recent time interval
    page.driver.execute_script(rightarrow)
    expect(page).to have_content("Overall (median) 60.00 min")
  end

  scenario "Unauthorized user access" do
    # Unauthenticated access
    User.unauthenticate!
    visit "/certification/stats"
    expect(page).not_to have_content("Activity for")
    expect(page).not_to have_content("Certification Rate")
    expect(page).not_to have_content("Time to Certify")
    expect(page).not_to have_content("Missing Documents")

    # Authenticated access without System Admin role
    User.authenticate!
    visit "/certification/stats"
    expect(page).not_to have_content("Activity for")
    expect(page).not_to have_content("Certification Rate")
    expect(page).not_to have_content("Time to Certify")
    expect(page).not_to have_content("Missing Documents")

    expect(page).to have_content("You aren't authorized to use this part of Caseflow yet.")
    expect(page).to have_content("Unauthorized")
  end
end
