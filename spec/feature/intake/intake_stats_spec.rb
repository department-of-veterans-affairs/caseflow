# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

RSpec.feature "Intake Stats Dashboard", :postgres, skip: "deprecated" do
  before do
    Timecop.freeze(Time.utc(2020, 1, 7, 17, 55, 0, rand(1000)))
  end

  after do
    Timecop.return
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["Admin Intake"])

    create(:ramp_election, veteran_file_number: "77776661", notice_date: 1.day.ago)
    create(:ramp_election, veteran_file_number: "77776662", notice_date: 1.day.ago)

    ramp_election = create(:ramp_election,
                           veteran_file_number: "77776663",
                           notice_date: 7.days.ago,
                           receipt_date: 45.minutes.ago,
                           option_selected: :supplemental_claim,
                           established_at: Time.zone.now)

    ramp_election.issues.create!(description: "an issue")
    ramp_election.issues.create!(description: "another issue")
    ramp_election.issues.create!(description: "yet another issue")

    create(:ramp_election,
           veteran_file_number: "77776663",
           notice_date: 5.days.ago,
           receipt_date: 45.minutes.ago,
           option_selected: :higher_level_review,
           established_at: Time.zone.now).issues.create!(description: "this is the only issue here")

    election_for_closed_appeals = create(
      :ramp_election,
      veteran_file_number: "77776666",
      notice_date: 5.days.ago,
      receipt_date: 2.days.ago,
      option_selected: :higher_level_review_with_hearing,
      established_at: Time.zone.now
    )

    RampClosedAppeal.create!(
      ramp_election_id: election_for_closed_appeals.id,
      vacols_id: "12345",
      nod_date: 365.days.ago
    )

    RampClosedAppeal.create!(
      ramp_election_id: election_for_closed_appeals.id,
      vacols_id: "54321",
      nod_date: 363.days.ago
    )

    # RAMP election with no notice date
    create(:ramp_election,
           veteran_file_number: "77776663",
           receipt_date: 45.minutes.ago,
           option_selected: :higher_level_review,
           established_at: Time.zone.now)

    RampElectionIntake.create!(
      veteran_file_number: "1111",
      completed_at: 3.hours.ago,
      completion_status: :success,
      user: current_user
    )

    RampElectionIntake.create!(
      veteran_file_number: "2222",
      completed_at: 5.hours.ago,
      completion_status: :error,
      error_code: :no_active_appeals,
      user: current_user
    )

    [:supplemental_claim, :higher_level_review, :higher_level_review_with_hearing, :appeal].each do |type|
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 2.years.ago,
             receipt_date: 1.year.ago,
             option_selected: :supplemental_claim,
             established_at: 1.year.ago + 2.days)

      RampRefiling.create!(
        veteran_file_number: "64205555",
        receipt_date: 45.minutes.ago,
        option_selected: type,
        appeal_docket: type == :appeal && :direct_review,
        established_at: Time.zone.now
      )
    end

    # Add an "in progress" refiling to make sure it doesn't show up
    RampRefiling.create!(
      veteran_file_number: "64205555",
      receipt_date: 45.minutes.ago,
      option_selected: :appeal,
      appeal_docket: :direct_review,
      established_at: nil
    )

    expect(CalculateIntakeStatsJob).to receive(:perform_later).twice
    visit "/intake/stats"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January (so far)")
    expect(find("#ramp-elections-sent")).to have_content("Total\n4")
    expect(find("#ramp-elections-sent")).to have_content("Higher-Level Reviews Returned\n1")
    expect(find("#ramp-elections-sent")).to have_content("Higher-Level Reviews with Informal Conference Returned\n1")
    expect(find("#ramp-elections-sent")).to have_content("Supplemental Claims Returned\n0")
    expect(find("#ramp-elections-sent")).to have_content("Total Returned\n2")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned\n50 %")
    expect(find("#ramp-elections-sent")).to have_content("Average Response Time\n4.00 days")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January (so far)")
    expect(find("#ramp-elections-received")).to have_content("Total\n4")
    expect(find("#ramp-elections-received")).to have_content("Higher-Level Reviews\n2")
    expect(find("#ramp-elections-received")).to have_content("Higher-Level Reviews with Informal Conference\n1")
    expect(find("#ramp-elections-received")).to have_content("Supplemental Claims\n1")
    expect(find("#ramp-elections-received")).to have_content("Total Issues\n4")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time\n5.00 days")
    expect(find("#ramp-elections-received")).to have_content("Average Time since Notice of Disagreement\n364.00 days")
    expect(find("#ramp-elections-received")).to have_content("Average Control Time\n12.00 hours")

    expect(find("#ramp-elections-processed")).to have_content("RAMP Elections Processed for January (so far)")
    expect(find("#ramp-elections-processed")).to have_content("Total\n2")
    expect(find("#ramp-elections-processed")).to have_content("Eligible\n1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible\n1")
    expect(find("#ramp-elections-processed")).to have_content("Percent Ineligible\n50")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Ineligible Appeals\n0")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - No Appeals\n1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Duplicate\n0")

    expect(find("#ramp-refilings-received")).to have_content("RAMP Refilings Received for January (so far)")
    expect(find("#ramp-refilings-received")).to have_content("Total\n4")
    expect(find("#ramp-refilings-received")).to have_content("Higher-Level Reviews\n1")
    expect(find("#ramp-refilings-received")).to have_content("Higher-Level Reviews with Informal Conference\n1")
    expect(find("#ramp-refilings-received")).to have_content("Supplemental Claims\n1")
    expect(find("#ramp-refilings-received")).to have_content("Appeals\n1")

    expect(CalculateIntakeStatsJob).to receive(:perform_later)

    click_on "Daily"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January 7")
    expect(find("#ramp-elections-sent")).to have_content("Total\n0")
    expect(find("#ramp-elections-sent")).to have_content("Higher-Level Reviews Returned\n0")
    expect(find("#ramp-elections-sent")).to have_content("Higher-Level Reviews with Informal Conference Returned\n0")
    expect(find("#ramp-elections-sent")).to have_content("Supplemental Claims Returned\n0")
    expect(find("#ramp-elections-sent")).to have_content("Total Returned\n0")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned\n?? %")
    expect(find("#ramp-elections-sent")).to have_content("Average Response Time\n?? sec")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January 7")
    expect(find("#ramp-elections-received")).to have_content("Total\n3")
    expect(find("#ramp-elections-received")).to have_content("Higher-Level Reviews\n2")
    expect(find("#ramp-elections-received")).to have_content("Higher-Level Reviews with Informal Conference\n0")
    expect(find("#ramp-elections-received")).to have_content("Supplemental Claims\n1")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time\n6.00 days")

    click_on "By Fiscal Year"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for FY 2020 (so far)")
  end

  scenario "Fiscal Year tab shows correct year after October 1" do
    Timecop.freeze(Time.utc(2020, 11, 7, 17, 55, 0, rand(1000)))
    User.authenticate!(roles: ["Admin Intake"])
    expect(CalculateIntakeStatsJob).to receive(:perform_later)
    visit "/intake/stats/fiscal_yearly"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for FY 2021 (so far)")
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/stats"
    expect(page).to have_content("You aren't authorized")
  end
end
