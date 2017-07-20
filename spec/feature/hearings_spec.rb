require "rails_helper"

RSpec.feature "Hearings" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1))
  end

  context "Upcoming Hearing Days" do
    let!(:current_user) do
      User.authenticate!(roles: ["Hearings"])
    end

    before do
      current_user.update!(full_name: "Lauren Roth", vacols_id: "LROTH")

      2.times do
        Generators::Hearing.build(
          user: current_user,
          date: 5.days.from_now,
          type: "video"
        )
      end

      Generators::Hearing.build(
        user: current_user,
        type: "central_office",
        date: Time.zone.now
      )
    end

    scenario "Shows dockets for each day" do
      visit "/hearings/dockets"

      expect(page).to have_content("Upcoming Hearing Days")

      # Verify user
      expect(page).to have_content("VLJ: Lauren Roth")

      # Verify dates

      day1 = get_day(1)
      day2 = get_day(2)

      expect(day1 + 5.days).to eql(day2)

      # Verify docket types

      docket1_type = get_type(1)
      docket2_type = get_type(2)

      expect(docket1_type).to eql("CO")
      expect(docket2_type).to eql("Video")

      # Verify hearings count in each docket

      docket1_hearings = get_hearings(1)
      docket2_hearings = get_hearings(2)

      expect(docket1_hearings).to eql("1")
      expect(docket2_hearings).to eql("2")

      # Validate help link
      find('#menu-trigger').click
      find_link("Help").click
      expect(page).to have_content("Caseflow Hearings Help")
    end

    scenario "User visits page without a vacols_id" do
      current_user.update!(vacols_id: nil)
      visit "/hearings/dockets"
      expect(page).to have_content("Page not found")
    end

    scenario "Shows a daily docket" do
      visit "/hearings/dockets/2017-01-05"
      expect(page).to have_content("Daily Docket")
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_selector("tbody", 2)
    end

    scenario "Shows a hearing worksheet" do
      visit "/hearings/dockets/2017-01-05"

      link = find(".cf-hearings-docket-appellant", match: :first).find("a")
      link_text = link.text

      link.click
      expect(page).to have_content("Hearing Worksheet")
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_content("Veteran ID: #{link_text}")

      visit "/hearings/worksheets/#{link_text}"
      expect(page).to have_content("Hearing Worksheet")
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_content("Veteran ID: #{link_text}")
    end
  end
end

# helpers

def get_day(row)
  parts = find(:xpath, "//tbody/tr[#{row}]/td[1]").text.split("/").map(&:to_i)
  Date.new(parts[2], parts[0], parts[1])
end

def get_type(row)
  find(:xpath, "//tbody/tr[#{row}]/td[3]").text
end

def get_hearings(row)
  find(:xpath, "//tbody/tr[#{row}]/td[6]").text
end
