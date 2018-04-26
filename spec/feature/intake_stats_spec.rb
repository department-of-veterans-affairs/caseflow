require "rails_helper"

RSpec.feature "Intake Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2020, 1, 7, 17, 55, 0, rand(1000)))
  end

  after do
    Timecop.return
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["Admin Intake"])

    RampElection.create!(veteran_file_number: "77776661", notice_date: 1.day.ago)
    RampElection.create!(veteran_file_number: "77776662", notice_date: 1.day.ago)

    ramp_election = RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 7.days.ago,
      receipt_date: 45.minutes.ago,
      option_selected: :supplemental_claim,
      established_at: Time.zone.now,
      end_product_reference_id: "132",
      end_product_status: "VERY_ACTIVE"
    )
    # Create an election with multiple issues
    ramp_election.issues.create!(description: "an issue")
    ramp_election.issues.create!(description: "another issue")
    ramp_election.issues.create!(description: "yet another issue")

    RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 5.days.ago,
      receipt_date: 45.minutes.ago,
      option_selected: :higher_level_review,
      established_at: Time.zone.now,
      end_product_reference_id: "132",
      end_product_status: "HELLA_ACTIVE"
    ).issues.create!(description: "this is the only issue here")

    RampElection.create!(
      veteran_file_number: "77776666",
      notice_date: 5.days.ago,
      receipt_date: 2.days.ago,
      option_selected: :higher_level_review_with_hearing,
      established_at: Time.zone.now
    )

    RampClosedAppeal.create!(
      ramp_election_id: 5,
      vacols_id: "12345",
      nod_date: 365.days.ago
    )

    RampClosedAppeal.create!(
      ramp_election_id: 5,
      vacols_id: "54321",
      nod_date: 363.days.ago
    )

    # RAMP election with no notice date
    RampElection.create!(
      veteran_file_number: "77776663",
      receipt_date: 45.minutes.ago,
      option_selected: :higher_level_review,
      established_at: Time.zone.now
    )

    RampElectionIntake.create!(
      veteran_file_number: "1111",
      completed_at: 3.hours.ago,
      completion_status: :success,
      user: current_user
    )

    RampElectionIntake.create!(
      veteran_file_number: "1111",
      completed_at: 2.hours.ago,
      completion_status: :error,
      error_code: :ramp_election_already_complete,
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
      completed_ramp_election = RampElection.create!(
        veteran_file_number: "64205555",
        notice_date: 2.years.ago,
        receipt_date: 1.year.ago,
        option_selected: :supplemental_claim,
        established_at: 1.year.ago + 2.days
      )

      RampRefiling.create!(
        ramp_election: completed_ramp_election,
        veteran_file_number: "64205555",
        receipt_date: 45.minutes.ago,
        option_selected: type,
        end_product_reference_id: ((type == :appeal) ? nil : "123"),
        appeal_docket: type == :appeal && :direct_review,
        established_at: Time.zone.now
      )
    end

    # Add an "in progress" refiling to make sure it doesn't show up
    RampRefiling.create!(
      ramp_election: RampElection.last,
      veteran_file_number: "64205555",
      receipt_date: 45.minutes.ago,
      option_selected: :appeal,
      end_product_reference_id: nil,
      appeal_docket: :direct_review,
      established_at: nil
    )

    expect(CalculateIntakeStatsJob).to receive(:perform_later).twice
    visit "/intake/stats"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January (so far)")
    expect(find("#ramp-elections-sent")).to have_content("Total 4")
    expect(find("#ramp-elections-sent")).to have_content("Higher Level Reviews Returned 1")
    expect(find("#ramp-elections-sent")).to have_content("Higher Level Reviews with Hearing Returned 1")
    expect(find("#ramp-elections-sent")).to have_content("Supplemental Claims Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Total Returned 2")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned 50 %")
    expect(find("#ramp-elections-sent")).to have_content("Average Response Time 4.00 days")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January (so far)")
    expect(find("#ramp-elections-received")).to have_content("Total 4")
    expect(find("#ramp-elections-received")).to have_content("Higher Level Reviews 2")
    expect(find("#ramp-elections-received")).to have_content("Higher Level Reviews with Hearing 1")
    expect(find("#ramp-elections-received")).to have_content("Supplemental Claims 1")
    expect(find("#ramp-elections-received")).to have_content("Total Issues 4")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time 5.00 days")
    expect(find("#ramp-elections-received")).to have_content("Average Time since Notice of Disagreement 364.00 days")
    expect(find("#ramp-elections-received")).to have_content("Average Control Time 12.00 hours")

    expect(find("#ramp-elections-processed")).to have_content("RAMP Elections Processed for January (so far)")
    expect(find("#ramp-elections-processed")).to have_content("Total 2")
    expect(find("#ramp-elections-processed")).to have_content("Eligible 1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible 1")
    expect(find("#ramp-elections-processed")).to have_content("Percent Ineligible 50")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Ineligible Appeals 0")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - No Appeals 1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Duplicate 0")

    expect(find("#ramp-refilings-received")).to have_content("RAMP Refilings Received for January (so far)")
    expect(find("#ramp-refilings-received")).to have_content("Total 4")
    expect(find("#ramp-refilings-received")).to have_content("Higher Level Reviews 1")
    expect(find("#ramp-refilings-received")).to have_content("Higher Level Reviews with Hearing 1")
    expect(find("#ramp-refilings-received")).to have_content("Supplemental Claims 1")
    expect(find("#ramp-refilings-received")).to have_content("Appeals 1")

    expect(CalculateIntakeStatsJob).to receive(:perform_later)

    click_on "Daily"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January 7")
    expect(find("#ramp-elections-sent")).to have_content("Total 0")
    expect(find("#ramp-elections-sent")).to have_content("Higher Level Reviews Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Higher Level Reviews with Hearing Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Supplemental Claims Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Total Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned ?? %")
    expect(find("#ramp-elections-sent")).to have_content("Average Response Time ?? sec")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January 7")
    expect(find("#ramp-elections-received")).to have_content("Total 3")
    expect(find("#ramp-elections-received")).to have_content("Higher Level Reviews 2")
    expect(find("#ramp-elections-received")).to have_content("Higher Level Reviews with Hearing 0")
    expect(find("#ramp-elections-received")).to have_content("Supplemental Claims 1")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time 6.00 days")

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
