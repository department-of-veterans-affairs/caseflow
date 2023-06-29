# frozen_string_literal: true

RSpec.feature "Intake Manager Page", :postgres do
  before do
    Timecop.freeze(post_ramp_start_date)
  end

  context "As a user with Admin Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Admin Intake"])
    end

    let(:date_mdY) { Time.zone.yesterday.mdY }

    scenario "Has access to intake manager page", :aggregate_failures do
      visit "/intake/manager"
      expect(page).to have_content("Intake Stats per User")
      expect(page).to have_content("Enter the User ID")
    end

    scenario "Only included errors and cancellations appear", :aggregate_failures do
      RampElectionIntake.create!(
        veteran_file_number: "1100",
        completed_at: 5.minutes.ago,
        completion_status: :canceled,
        user: current_user
      )

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

      let!(intake_user) = User.create!

      visit "/intake/manager"

      select_user_stats(css_id)

      expect(page).to have_table(".usa-table-borderless")

      expect(find("#table-row-4")).to have_content("1100")
      expect(find("#table-row-4")).to_not have_content(":")

      expect(find("#table-row-3")).to have_content("1110")
      expect(find("#table-row-3")).to have_content(date_mdY)
      expect(find("#table-row-3")).to have_content(current_user.full_name)
      expect(find("#table-row-3")).to have_content("RAMP Opt-In Election Form")
      expect(find("#table-row-3")).to have_content("Error: sensitivity")

      expect(find("#table-row-2")).to have_content("1111")
      expect(find("#table-row-2")).to have_content(date_mdY)
      expect(find("#table-row-2")).to have_content(current_user.full_name)
      expect(find("#table-row-2")).to have_content("21-4138 RAMP Selection Form")
      expect(find("#table-row-2")).to have_content("Error: sensitivity")

      expect(find("#table-row-1")).to have_content("Canceled: duplicate EP created outside Caseflow")
      expect(find("#table-row-0")).to have_content("Canceled: I am canceled just because")

      expect(page).not_to have_selector("#table-row-5")
    end

    def select_user_stats(css_id)
      fill_in "Enter the User ID", with: css_id
      click_on "Search"
    end

    scenario "choose a user to see stats" do
      veteran_file_number = "1234"
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)
      busy_day = 3.days.ago.beginning_of_day

      5.times do
        Intake.create!(
          user: user1,
          veteran_file_number: veteran_file_number,
          detail_type: "SupplementalClaim",
          completed_at: busy_day,
          completion_status: "success"
        )
      end
      3.times do
        Intake.create!(
          user: user2,
          veteran_file_number: veteran_file_number,
          detail_type: "HigherLevelReview",
          completed_at: busy_day - 2.days,
          completion_status: "success"
        )
      end

      visit "/intake/manager"

      busy_day_ymd = busy_day.strftime("%F")

      expect(page).to_not have_content(busy_day_ymd)
      expect(page).to_not have_content("5")

      select_user_stats(user1.css_id)
      expect(page).to have_content("#{busy_day_ymd} 5")

      select_user_stats(user2.css_id)
      expect(page).to have_content("#{(busy_day - 2.days).strftime('%F')} 3")

      select_user_stats(user3.css_id)
      expect(page).to have_content("No stats available.")

      select_user_stats("nosuchuser")
      expect(page).to have_content("Not found: nosuchuser")

      visit "/intake/manager?user_css_id=#{user1.css_id}"

      expect(page).to have_content("#{busy_day_ymd} 5")
    end
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/manager"
    expect(page).to have_content("You aren't authorized")
  end
end
