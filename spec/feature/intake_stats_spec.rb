require "rails_helper"

RSpec.feature "Intake Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 7, 17, 55, 0, rand(1000)))
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["Admin Intake"])

    RampElection.create!(veteran_file_number: "77776661", notice_date: 1.day.ago)
    RampElection.create!(veteran_file_number: "77776662", notice_date: 1.day.ago)
    RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 7.days.ago,
      receipt_date: 45.minutes.ago,
      end_product_reference_id: "132"
    )

    RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 5.days.ago,
      receipt_date: 45.minutes.ago,
      end_product_reference_id: "132"
    )

    # RAMP election with no notice date
    RampElection.create!(
      veteran_file_number: "77776663",
      receipt_date: 45.minutes.ago,
      end_product_reference_id: "132"
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

    expect(CalculateIntakeStatsJob).to receive(:perform_later)
    visit "/intake/stats"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January (so far)")
    expect(find("#ramp-elections-sent")).to have_content("Total 3")
    expect(find("#ramp-elections-sent")).to have_content("Number Returned 1")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned 33 %")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January (so far)")
    expect(find("#ramp-elections-received")).to have_content("Total 3")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time 6.00 days")

    expect(find("#ramp-elections-processed")).to have_content("RAMP Elections Processed for January (so far)")
    expect(find("#ramp-elections-processed")).to have_content("Total 2")
    expect(find("#ramp-elections-processed")).to have_content("Eligible 1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible 1")
    expect(find("#ramp-elections-processed")).to have_content("Percent Ineligible 50")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Ineligible Appeals 0")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - No Appeals 1")
    expect(find("#ramp-elections-processed")).to have_content("Ineligible - Duplicate 0")

    expect(CalculateIntakeStatsJob).to receive(:perform_later)

    click_on "Daily"
    expect(find("#ramp-elections-sent")).to have_content("RAMP Elections Sent for January 7")
    expect(find("#ramp-elections-sent")).to have_content("Total 0")
    expect(find("#ramp-elections-sent")).to have_content("Number Returned 0")
    expect(find("#ramp-elections-sent")).to have_content("Percentage Returned ?? %")

    expect(find("#ramp-elections-received")).to have_content("RAMP Elections Received for January 7")
    expect(find("#ramp-elections-received")).to have_content("Total 3")
    expect(find("#ramp-elections-received")).to have_content("Average Response Time 6.00 days")
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/stats"
    expect(page).to have_content("You aren't authorized")
  end
end
