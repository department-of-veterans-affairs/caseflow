# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Hearing Prep" do
  context "Upcoming hearing days" do
    let!(:current_user) { User.authenticate!(roles: ["Hearing Prep"]) }
    let!(:vacols_staff) { create(:staff, user: current_user) }

    before do
      2.times do
        create(:case_hearing,
               board_member: vacols_staff.sattyid,
               hearing_date: Time.zone.today + 50.days,
               folder_nr: create(:case).bfkey)
      end
      create(:case_hearing,
             board_member: vacols_staff.sattyid,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: Time.zone.today + 25.days,
             folder_nr: create(:case).bfkey)
      create(:case_hearing, board_member: vacols_staff.sattyid,
                            hearing_type: HearingDay::REQUEST_TYPES[:central],
                            hearing_date: Time.zone.today - 3.days)
      create(:case_hearing,
             board_member: vacols_staff.sattyid,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: Time.zone.today - 6.days,
             folder_nr: create(:case).bfkey)
      create(:hearing, hearing_day: create(:hearing_day, judge: current_user, scheduled_for: 5.days.from_now))
      create(:case_hearing,
             board_member: vacols_staff.sattyid,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: Hearing.first.scheduled_for,
             folder_nr: create(:case).bfkey)
    end

    scenario "Shows upcoming dockets for upcoming day" do
      visit "/hearings/dockets"

      expect(page).to have_content("Your Hearing Days")

      # Verify user
      expect(page).to have_content("VLJ: Lauren Roth")

      # Verify dates
      expect(get_day(1).to_date).to eql Hearing.first.scheduled_for.to_date
      expect(get_day(2).to_date).to eql 25.days.from_now.to_date
      expect(get_day(3).to_date).to eql 50.days.from_now.to_date

      # Verify docket types
      expect(get_type(1)).to eql("Central")
      expect(get_type(2)).to eql("Central")
      expect(get_type(3)).to eql("Video")

      # Verify hearings count in each docket
      expect(get_hearings(1)).to eql("2")
      expect(get_hearings(2)).to eql("1")
      expect(get_hearings(3)).to eql("2")

      # Validate help link
      find("a", text: "DSUSER (DSUSER)").click
      find_link("Help").click
      expect(page).to have_content("Welcome to the Hearings Help page!")
    end

    scenario "Shows past dockets for each day" do
      visit "/hearings/dockets"

      click_on("dockets-tab-1")

      # Verify docket types
      expect(get_type(1)).to eql("Central")

      # Verify hearings count in each docket
      expect(get_hearings(1)).to eql("1")
    end

    scenario "Upcoming docket days correctly handles master records" do
      visit "/hearings/dockets"
      expect(page).not_to have_link(50.days.from_now.strftime("%-m/%-d/%Y"))
      expect(page).to have_content(50.days.from_now.strftime("%-m/%-d/%Y"))
      expect(page).not_to have_link(Time.zone.now.strftime("%-m/%-d/%Y"))
    end
  end
end

# helpers

def get_day(row)
  date_row = find(:xpath, "//tbody/tr[#{row}]/td[1]").text
  parts = date_row[/\d{1,2}\/\d{1,2}\/\d{4}/].split("/").map(&:to_i)
  Date.new(parts[2], parts[0], parts[1])
end

def get_type(row)
  find(:xpath, "//tbody/tr[#{row}]/td[3]").text
end

def get_hearings(row)
  find(:xpath, "//tbody/tr[#{row}]/td[6]").text
end
