require "rails_helper"

RSpec.feature "Hearings" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1, 13))
  end

  context "Hearings Prep" do
    let!(:current_user) { User.authenticate!(roles: ["Hearing Prep"]) }

    let!(:vacols_staff) { create(:staff, user: current_user) }

    let!(:hearing) { create(:hearing, user: current_user) }

    before do
      2.times do
        create(:case_hearing,
               board_member: vacols_staff.sattyid,
               hearing_date: 5000.days.from_now,
               folder_nr: create(:case).bfkey)
      end
      create(:case_hearing,
             board_member: vacols_staff.sattyid,
             hearing_type: "C",
             hearing_date: 2500.days.from_now,
             folder_nr: create(:case).bfkey)
      create(:case_hearing, board_member: vacols_staff.sattyid, hearing_type: "C", hearing_date: 3.days.ago)
      create(:case_hearing,
             board_member: vacols_staff.sattyid,
             hearing_type: "C",
             hearing_date: 6.days.ago,
             folder_nr: create(:case).bfkey)
    end

    scenario "Shows upcoming dockets for upcoming day" do
      visit "/hearings/dockets"

      expect(page).to have_content("Your Hearing Days")

      # Verify user
      expect(page).to have_content("VLJ: Lauren Roth")

      # Verify dates
      day1 = get_day(1)
      day2 = get_day(2)

      expect(day1 + 2500.days).to eql(day2)

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
      find("#menu-trigger").click
      find_link("Help").click
      expect(page).to have_content("Welcome to the Hearings Help page!")
    end

    scenario "Shows past dockets for each day" do
      visit "/hearings/dockets"

      click_on("dockets-tab-1")

      # Verify docket types

      docket1_type = get_type(1)

      expect(docket1_type).to eql("Video")

      # Verify hearings count in each docket

      docket1_hearings = get_hearings(1)

      expect(docket1_hearings).to eql("1")
    end

    scenario "Upcoming docket days correctly handles master records" do
      visit "/hearings/dockets"
      expect(page).not_to have_link(5000.days.from_now.strftime("%-m/%-d/%Y"))
      expect(page).to have_content(5000.days.from_now.strftime("%-m/%-d/%Y"))
      expect(page).not_to have_link(Time.zone.now.strftime("%-m/%-d/%Y"))
    end

    scenario "Shows a daily docket" do
      visit "/hearings/dockets/2030-09-10"

      expect(page).to have_content("Daily Docket")
      expect(page).to have_content("9/10/2030")
      expect(page).to have_content("Hearing Type: Video")
      expect(page).to have_selector("tbody", 2)

      find_link("Back to Your Hearing Days").click
      expect(page).to have_content("Your Hearing Days")
    end

    scenario "Daily docket saves to the backend", skip: "Test is flakey" do
      visit "/hearings/dockets/2023-11-06"

      fill_in "3.notes", with: "This is a note about the hearing!"
      find(".cf-hearings-prepped").find(".cf-form-checkbox").click
      find(".dropdown-3-disposition").click
      find("#react-select-2--option-1").click
      find(".dropdown-3-hold_open").click
      find("#react-select-3--option-2").click
      find(".dropdown-3-aod").click
      find("#react-select-4--option-2").click
      find("label", text: "Transcript Requested").click
      visit "/hearings/dockets/2023-11-06"
      expect(page).to have_content("This is a note about the hearing!")
      expect(page).to have_content("No Show")
      expect(page).to have_content("60 days")
      expect(page).to have_content("None")
      expect(find_field("Transcript Requested", visible: false)).to be_checked
      expect(find_field("3-prep", visible: false)).to be_checked
    end

    scenario "Link on daily docket opens worksheet in new tab" do
      visit "/hearings/dockets/2023-11-06"
      link_cell = find(".cf-hearings-docket-appellant", match: :first)

      # Link should be bolded before the worksheet has been viewed
      expect(link_cell).to have_css("strong a")

      link = link_cell.find("a")
      link_href = link[:href]

      link.click

      # Link should not be bolded after we click the link to view the worksheet
      expect(link_cell).to_not have_css("strong a")

      new_window = windows.last
      page.within_window new_window do
        visit link_href
        expect(page).to have_content("Hearing Worksheet")
      end

      # If we refresh the page, the view hearing link should still be unbolded.
      visit "/hearings/dockets/2023-11-06"
      link_cell = find(".cf-hearings-docket-appellant", match: :first)
      expect(link_cell).to_not have_css("strong a")
    end

    scenario "Hearing worksheet page displays worksheet information" do
      visit "/hearings/" + hearing.id.to_s + "/worksheet"

      expect(page).to have_content("HEARING TYPE Video")
      expect(page).to have_content("Docket #" + hearing.docket_number)
      expect(page.title).to eq hearing.veteran_fi_last_formatted + "'s Hearing Worksheet"
    end

    context "worksheet header" do
      before do
        create(:hearing, user: current_user)
      end

      scenario "Hearing worksheet switch veterans" do
        visit "/hearings/" + hearing.id.to_s + "/worksheet"

        find(".Select-control").click
        find("#react-select-2--option-0").click
        expect(page).to have_current_path("/hearings/1/worksheet")
        expect(page).to have_content(Hearing.find(1).veteran_first_name)

        find(".Select-control").click
        find("#react-select-2--option-1").click
        expect(page).to have_current_path("/hearings/2/worksheet")
        expect(page).to have_content(Hearing.find(2).veteran_first_name)
      end
    end

    scenario "Hearing worksheet default summary shows up" do
      visit "/hearings/" + hearing.id.to_s + "/worksheet"
      expect(page).to have_content("Contentions")
      expect(page).to have_content("Evidence")
      expect(page).to have_content("Comments and special instructions to attorneys")
    end

    scenario "Worksheet saves on refresh" do
      visit "/hearings/" + hearing.id.to_s + "/worksheet"
      page.find(".public-DraftEditor-content").set("These are the notes being taken here")
      fill_in "appellant-vet-rep-name", with: "This is a rep name"
      fill_in "appellant-vet-witness", with: "This is a witness"
      fill_in "worksheet-military-service", with: "This is military service"

      visit "/hearings/" + hearing.id.to_s + "/worksheet"
      expect(page).to have_content("This is a rep name")
      expect(page).to have_content("This is a witness")
      expect(page).to have_content("These are the notes being taken here")
      expect(page).to have_content("This is military service")

      visit "/hearings/" + hearing.id.to_s + "/worksheet/print?do_not_open_print_prompt=1"
      expect(page).to have_content("This is a rep name")
      expect(page).to have_content("This is a witness")
      expect(page).to have_content("These are the notes being taken here")
      expect(page).to have_content("This is military service")
    end

    scenario "Worksheet adds, deletes, edits, and saves user created issues" do
      visit "/hearings/" + hearing.id.to_s + "/worksheet"

      click_on "button-addIssue-1"
      fill_in "3-issue-description", with: "This is the description"
      fill_in "3-issue-notes", with: "This is a note"
      fill_in "3-issue-disposition", with: "This is a disposition"

      expect(page).to have_content("Vba_burial:")
      find("#cf-issue-delete-11").click
      click_on "Confirm delete"
      find("#cf-issue-delete-12").click
      click_on "Confirm delete"
      expect(page).to_not have_content("Vba_burial:")

      visit "/hearings/" + hearing.id.to_s + "/worksheet"
      expect(page).to have_content("This is the description")
      expect(page).to have_content("This is a note")
      expect(page).to have_content("This is a disposition")
      expect(page).to_not have_content("Service Connection")
    end

    context "Multiple appeal streams" do
      before do
        vbms_id = hearing.appeal.vbms_id
        create(:case_with_form_9, bfcorlid: vbms_id, case_issues:
            [create(:case_issue), create(:case_issue)])
      end

      scenario "Numbering is consistent" do
        visit "/hearings/" + hearing.id.to_s + "/worksheet"

        click_on "button-addIssue-2"
        expect(page).to have_content("5.")
        find("#cf-issue-delete-11").click
        click_on "Confirm delete"
        expect(page).to_not have_content("5.")
      end
    end

    scenario "Can click from hearing worksheet to reader" do
      visit "/hearings/" + hearing.id.to_s + "/worksheet"
      link = find("#review-claims-folder")
      link_href = link[:href]
      expect(page).to have_content("Review claims folder")
      click_on "Review claims folder"
      new_window = windows.last
      page.within_window new_window do
        visit link_href
        expect(page).to have_content("You've viewed 0 out of 3 documents")
      end
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
