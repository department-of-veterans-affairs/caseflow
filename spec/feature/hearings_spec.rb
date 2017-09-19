require "rails_helper"

RSpec.feature "Hearings" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1, 13))
  end

  let(:appeal) do
    Generators::Appeal.create
  end

  context "Upcoming Hearing Days" do
    let!(:current_user) do
      User.authenticate!(roles: ["Hearing Prep"])
    end

    before do
      2.times do |id|
        Generators::Hearing.create(
          id: id,
          user: current_user,
          date: 5.days.from_now,
          type: "video"
        )
      end

      Generators::Hearing.build(
        id: 3,
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

    scenario "Shows a daily docket" do
      visit "/hearings/dockets/2017-01-06"
      expect(page).to have_content("Daily Docket")
      expect(page).to have_content("1/6/2017")
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_selector("tbody", 2)

      find_link("Back to Upcoming Hearing Days").click
      expect(page).to have_content("Upcoming Hearing Days")
    end

    scenario "Shows a hearing worksheet" do
      visit "/hearings/dockets/2017-01-06"

      link = find(".cf-hearings-docket-appellant", match: :first).find("a")
      link_href = link[:href]

      link.click
      new_window = windows.last
      page.within_window new_window do
        expect(page).to have_content("The veteran believes their knee is hurt")
        expect(page).to have_content("Army 02/02/2003 - 05/07/2009")
        expect(page).to have_content("Medical exam occurred on 10/10/2008")
        expect(page).to have_content("Look for knee-related medical records")

        visit link_href
        expect(page).to have_content("Hearing Worksheet")

        # There's no functionality yet, but you should be able to...
        click_on "Review eFolder"
      end
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
