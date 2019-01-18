require "rails_helper"

RSpec.feature "Add a Hearing Day" do
  let!(:current_user) do
    OrganizationsUser.add_user_to_organization(hearings_user, HearingsManagement.singleton)
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  let!(:hearings_user) do
    create(:hearings_management)
  end

  context "Verify Initial Modal State And Basic Errors" do
    scenario "When opening modal verify initial fields present" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      expect(page).to have_content("Select Hearing Date")
      expect(page).to have_content("Select Hearing Type")
      expect(page).not_to have_content("Select Regional Office (RO)")
      expect(page).not_to have_content("Select VLJ (Optional)")
      expect(page).not_to have_content("Select Hearing Coordinator (Optional)")
      expect(page).to have_content("Notes (Optional)")
      expect(page).to have_content("Assign Board Hearing Room")
    end

    scenario "Open modal but do not fill form, expect error" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      find("button", text: "Confirm").click
      expect(page).to have_content("Cannot create a New Hearing Day")
      expect(page).to have_content("Please make sure you have entered a Hearing Date")
      expect(page).to have_content("Please make sure you have entered a Hearing Type")
    end
  end

  context "When adding a Central Office Hearing" do
    scenario "When opening modal and selecting Central Office verify correct fields present" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      click_dropdown(index: "C", text: "Central")
      expect(page).to have_content("Select VLJ (Optional)", wait: 30)
      expect(page).not_to have_content("Select Regional Office (RO)")
      expect(page).to have_content("Select Hearing Coordinator (Optional)")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      fill_in "hearingDate", with: "01152019"
      click_dropdown(index: "C", text: "Central")
      expect(page).to have_content("Select VLJ (Optional)", wait: 30)
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes (Optional)", with: "Test notes."
      find("button", text: "Confirm").click
      expect(page).to have_content("You have successfully added Hearing Day 01/15/2019", wait: 30)
    end
  end

  context "Add a Video Hearing Day" do
    scenario "When opening modal and selecting Central Office verify correct fields present" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Select Regional Office (RO)", wait: 30)
      expect(page).to have_content("Select VLJ (Optional)")
      expect(page).to have_content("Select Hearing Coordinator (Optional)")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      fill_in "hearingDate", with: "04152019"
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Select Regional Office (RO)", wait: 30)
      dropdowns = page.all(".Select-control")
      dropdowns[1].click
      dropdowns[1].sibling(".Select-menu-outer").find("div .Select-option", text: "Atlanta, GA").click
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes (Optional)", with: "Test notes."
      find("button", text: "Confirm").click
      expect(page).to have_content("You have successfully added Hearing Day 04/15/2019", wait: 30)
    end

    scenario "Leave Regional Office without a selection, expect error" do
      visit "hearings/schedule"
      expect(page).to have_content("Welcome to Hearing Schedule!")
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      fill_in "hearingDate", with: "04152019"
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Select Regional Office (RO)", wait: 30)
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes (Optional)", with: "Test notes."
      find("button", text: "Confirm").click
      expect(page).to have_content("Hearing type is a Video hearing")
      expect(page).to have_content("Please make sure you select a Regional Office")
    end
  end
end
