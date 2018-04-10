require "rails_helper"

RSpec.feature "Intake Manager Page" do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 8, 8))
  end

  context "As a user with Admin Intake role", :focus => true do
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

      # Errors that should appear

      RampElectionIntake.create!(
        veteran_file_number: "1110",
        completed_at: 0.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1111",
        completed_at: 1.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1112",
        completed_at: 2.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_valid,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1113",
        completed_at: 3.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_valid,
        user: current_user
      )

      # Cancellations

      RampElectionIntake.create!(
        veteran_file_number: "1114",
        completed_at: 4.hours.ago,
        completion_status: :canceled,
        cancel_reason: :duplicate_ep,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1115",
        completed_at: 5.hours.ago,
        completion_status: :canceled,
        cancel_reason: :system_error,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1116",
        completed_at: 6.hours.ago,
        completion_status: :canceled,
        cancel_reason: :missing_signature,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1117",
        completed_at: 7.hours.ago,
        completion_status: :canceled,
        cancel_reason: :veteran_clarification,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1118",
        completed_at: 8.hours.ago,
        completion_status: :canceled,
        cancel_reason: :other,
        cancel_other: 'I am canceled just because',
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1119",
        completed_at: 9.hours.ago,
        completion_status: :canceled,
        cancel_reason: :other,
        cancel_other: 'I am a canceled refiling',
        user: current_user
      )

      # Successes should not appear in the manager list
      RampElectionIntake.create!(
        veteran_file_number: "2110",
        completed_at: 20.hours.ago,
        completion_status: :success,
        user: current_user
      )

      # Errors that should not appear in the manager list

      election_excluded_errors = [
        :invalid_file_number,
        :veteran_not_found,
        :did_not_receive_ramp_election,
        :ramp_election_already_complete,
        :no_active_appeals,
        :no_eligible_appeals,
        :no_active_compensation_appeals,
        :no_active_fully_compensation_appeals,
        :duplicate_intake_in_progress,
      ]

      refiling_excluded_errors = [
        :no_complete_ramp_election,
        :ramp_election_is_active,
        :ramp_election_no_issues,
        :ramp_refiling_already_processed
      ]

      election_excluded_errors.each do |election_excluded_error|
        RampElectionIntake.create!(
          veteran_file_number: "2110",
          completed_at: 20.hours.ago,
          completion_status: :error,
          error_code: election_excluded_error,
          user: current_user
        )
      end

      refiling_excluded_errors.each do |refiling_excluded_error|
        RampRefilingIntake.create!(
          veteran_file_number: "2110",
          completed_at: 20.hours.ago,
          completion_status: :error,
          error_code: refiling_excluded_error,
          user: current_user
        )
      end

      visit "/intake/manager"

      expect(find("#table-row-0")).to have_content("1110")
      expect(find("#table-row-0")).to have_content("8/07/2017")
      expect(find("#table-row-0")).to have_content(current_user.full_name)
      expect(find("#table-row-0")).to have_content("RAMP Opt-In Election Form")
      expect(find("#table-row-0")).to have_content("Error: sensitivity")

      expect(find("#table-row-1")).to have_content("1111")
      expect(find("#table-row-1")).to have_content("8/07/2017")
      expect(find("#table-row-1")).to have_content(current_user.full_name)
      expect(find("#table-row-1")).to have_content("21-4138 RAMP Selection Form")
      expect(find("#table-row-1")).to have_content("Error: sensitivity")

      expect(find("#table-row-2")).to have_content("Error: missing profile information")
      expect(find("#table-row-3")).to have_content("Error: missing profile information")
      expect(find("#table-row-4")).to have_content("Canceled: Duplicate EP created outside Caseflow")
      expect(find("#table-row-5")).to have_content("Canceled: System error")
      expect(find("#table-row-6")).to have_content("Canceled: Missing signature")
      expect(find("#table-row-7")).to have_content("Canceled: Need clarification from Veteran")
      expect(find("#table-row-8")).to have_content("Canceled: I am canceled just because")
      expect(find("#table-row-9")).to have_content("Canceled: I am a canceled refiling")

      expect(page).not_to have_selector("#table-row-10")
    end

    scenario "An error disappears if there's since been a success on that file number" do
      RampElectionIntake.create!(
        veteran_file_number: "1110",
        completed_at: 0.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1111",
        completed_at: 1.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1112",
        completed_at: 2.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_valid,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1113",
        completed_at: 3.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_valid,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1113",
        completed_at: 5.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      visit "/intake/manager"

      expect(find("#table-row-3")).to have_content("missing profile information")
      expect(find("#table-row-4")).to have_content("sensitivity")

      RampElectionIntake.create!(
        veteran_file_number: "1110",
        completed_at: 20.hours.ago,
        completion_status: :success,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1111",
        completed_at: 30.hours.ago,
        completion_status: :success,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1112",
        completed_at: 1.hours.ago,
        completion_status: :success,
        user: current_user
      )

      RampRefilingIntake.create!(
        veteran_file_number: "1113",
        completed_at: 4.hours.ago,
        completion_status: :success,
        user: current_user
      )

      visit "/intake/manager"

      expect(find("#table-row-0")).to have_content("sensitivity")
      expect(find("#table-row-1")).to have_content("sensitivity")
      expect(find("#table-row-2")).to have_content("1113")
      expect(find("#table-row-2")).to have_content("missing profile information")
      expect(page).not_to have_content("1112")
      expect(page).not_to have_selector("#table-row-3")

    end
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/manager"
    expect(page).to have_content("You aren't authorized")
  end
end
