require "rails_helper"

RSpec.feature "Hearings" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1))
  end

  context "Schedule" do
    let!(:current_user) do
      User.authenticate!(roles: ["Hearings"])
    end

    scenario "Shows dockets for each day" do
      current_user.full_name = "Lauren Roth"
      current_user.vacols_id = "LROTH"
      current_user.save!

      Generators::Hearing.build(
        vacols_user_id: current_user.vacols_id
      )

      Generators::Hearing.build(
        vacols_user_id: current_user.vacols_id
      )

      Generators::Hearing.build(
        type: "central_office",
        date: Time.zone.now,
        vacols_user_id: current_user.vacols_id
      )

      visit "/hearings/dockets"

      # Verify dates

      day1 = get_day(1)
      day2 = get_day(2)

      expect(day1 + 5).to eql(day2)

      # Verify docket types

      docket1_type = get_type(1)
      docket2_type = get_type(2)

      expect(docket1_type).to eql("Video")
      expect(docket2_type).to eql("CO")

      # Verify hearings count in each docket

      docket1_hearings = get_hearings(1)
      docket2_hearings = get_hearings(2)

      expect(docket1_hearings).to eql("2")
      expect(docket2_hearings).to eql("1")

      # Validate help link
      find('#menu-trigger').click
      find_link("Help").click
      expect(page).to have_content("Caseflow Hearings Help")
    end
  end
end

# helpers

def get_day(row)
  # splits "YYYY/MM/DD" and converts DD to integer
  find(:xpath, "//tbody/tr[#{row}]/td[1]").text.split("/")[2].to_i
end

def get_type(row)
  find(:xpath, "//tbody/tr[#{row}]/td[3]").text
end

def get_hearings(row)
  find(:xpath, "//tbody/tr[#{row}]/td[6]").text
end
