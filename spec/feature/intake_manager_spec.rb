require "rails_helper"

RSpec.feature "Intake Manager Page" do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 12, 8))
  end

  context "As a user with Admin Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Admin Intake"])
    end

    scenario "Has access to intake manager page" do
      visit "/intake/manager"
      expect(page).to have_content("Claims for manager review")
      expect(page).to have_content("Veteran File Number")
      expect(page).to have_content("Date Processed")
      expect(page).to have_content("Form")
      expect(page).to have_content("Employee")
      expect(page).to have_content("Explanation")
    end

    scenario "Only included errors and cancellations appear" do
      RampElectionIntake.create!(
        veteran_file_number: "1110",
        completed_at: 10.minutes.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1111",
        completed_at: 1.hour.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1114",
        completed_at: 4.hours.ago,
        completion_status: :canceled,
        cancel_reason: :duplicate_ep,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1118",
        completed_at: 8.hours.ago,
        completion_status: :canceled,
        cancel_reason: :other,
        cancel_other: "I am canceled just because",
        user: current_user
      )

      visit "/intake/manager"

      expect(find("#table-row-3")).to have_content("1110")
      expect(find("#table-row-3")).to have_content("12/07/2017")
      expect(find("#table-row-3")).to have_content(current_user.full_name)
      expect(find("#table-row-3")).to have_content("RAMP Opt-In Election Form")
      expect(find("#table-row-3")).to have_content("Error: sensitivity")

      expect(find("#table-row-2")).to have_content("1111")
      expect(find("#table-row-2")).to have_content("12/07/2017")
      expect(find("#table-row-2")).to have_content(current_user.full_name)
      expect(find("#table-row-2")).to have_content("21-4138 RAMP Selection Form")
      expect(find("#table-row-2")).to have_content("Error: sensitivity")

      expect(find("#table-row-1")).to have_content("Canceled: duplicate EP created outside Caseflow")
      expect(find("#table-row-0")).to have_content("Canceled: I am canceled just because")

      expect(page).not_to have_selector("#table-row-4")
    end
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/manager"
    expect(page).to have_content("You aren't authorized")
  end
end
