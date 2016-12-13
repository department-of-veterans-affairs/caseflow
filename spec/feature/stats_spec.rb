require "rails_helper"

RSpec.feature "Stats Dashboard" do
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
      form8_started_at:    5.hours.ago,
      created_at:          5.hours.ago,
      completed_at:        nil
    )

    Certification.create(
      nod_matching_at:     4.hours.ago,
      form9_matching_at:   5.hours.ago,
      soc_matching_at:     5.hours.ago,
      ssocs_required:      true,
      ssocs_matching_at:   5.hours.ago,
      form8_started_at:    5.hours.ago,
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
    Stats.calculate_all!

    User.authenticate!
  end

  after { Timecop.return }

  scenario "Switching tab intervals" do
    visit "/stats"
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
    Stats.calculate_all!
    visit "/stats/daily"
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

  scenario "Toggle median to 95th percentile" do
    visit "/stats"
    click_on "Daily"

    find('*[role="button"]', text: "Overall (median)").trigger("click")
    expect(page).to have_content("Overall (95th percentile) 120.00 min")
    find('*[role="button"]', text: "Overall (95th percentile)").trigger("click")
    expect(page).to have_content("Overall (median) 60.00 min")
  end

  scenario "Navigate to past periods with arrow keys" do
    leftarrow = "d3.select(window).dispatch('keydown', { detail: { keyCode: 37 } })"

    visit "/stats"
    click_on "Monthly"
    expect(page).to have_content("Activity for January (so far)")

    12.times do
      page.driver.execute_script(leftarrow)
    end

    expect(page).to have_content("Activity for January 2014")
  end
end
