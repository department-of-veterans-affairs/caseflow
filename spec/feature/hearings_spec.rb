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

  context "Hearings Prep" do
    let!(:current_user) do
      User.authenticate!(roles: ["Hearing Prep"])
    end

    before do
      2.times do |id|
        Generators::Hearing.create(
          id: id,
          user: current_user,
          date: 5.days.from_now,
          type: "video",
          master_record: false
        )
      end

      Generators::Hearing.create(
        id: 3,
        user: current_user,
        type: "central_office",
        date: Time.zone.now,
        master_record: true
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

      # the first one is a master record
      expect(docket1_hearings).to eql("0")
      expect(docket2_hearings).to eql("2")

      # Validate help link
      find('#menu-trigger').click
      find_link("Help").click
      expect(page).to have_content("Caseflow Hearings Help")
    end

    scenario "Upcoming docket days correctly handles master records" do
      visit "/hearings/dockets"
      expect(page).to have_link(5.days.from_now.strftime("%-m/%-d/%Y"))
      expect(page).not_to have_link(Time.zone.now.strftime("%-m/%-d/%Y"))
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

    scenario "Daily docket saves to the backend" do
      visit "/hearings/dockets/2017-01-01"
      fill_in "3.notes", with: "This is a note about the hearing!"
      find("label", text: "Add on").click
      find("label", text: "Transcript Requested").click

      visit "/hearings/dockets/2017-01-01"
      expect(page).to have_content("This is a note about the hearing!")
      expect(find_field("Add on", visible: false)).to be_checked
      expect(find_field("Transcript Requested", visible: false)).to be_checked
    end

    scenario "Link on daily docket opens worksheet in new tab" do
      visit "/hearings/dockets/2017-01-06"
      link = find(".cf-hearings-docket-appellant", match: :first).find("a")
      link_href = link[:href]

      link.click
      new_window = windows.last
      page.within_window new_window do
        visit link_href
        expect(page).to have_content("Hearing Worksheet")
      end
    end

    scenario "Hearing worksheet page displays worksheet information" do
      visit "/hearings/1/worksheet"
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_content("Docket Number: 4198")
      expect(page).to have_content("Form 9: 12/21/2016")
      expect(page).to have_content("The veteran believes their knee is hurt")
      expect(page).to have_content("Army 02/13/2002 - 12/21/2003")
      expect(page).to have_content("Medical exam occurred on 10/10/2008")
      expect(page).to have_content("Look for knee-related medical records")
    end

    scenario "Worksheet differentiates between user and vacols created records" do
      visit "/hearings/1/worksheet"
      expect(page).to have_field("17-issue-program")
      expect(page).to have_field("17-issue-name")
      expect(page).to have_field("17-issue-levels")
      expect(page).to have_field("17-issue-description")
      expect(page).to_not have_field("66-issue-program")
      expect(page).to_not have_field("66-issue-name")
      expect(page).to_not have_field("66-issue-levels")
      expect(page).to have_field("66-issue-description")
    end

    scenario "Can click from hearing worksheet to reader" do
      visit "/hearings/1/worksheet"
      expect(page).to have_content("Review eFolder")
      click_on "Review eFolder"
      expect(page).to have_content("You've viewed 0 out of 4 documents")
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
