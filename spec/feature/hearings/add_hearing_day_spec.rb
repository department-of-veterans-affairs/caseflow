# frozen_string_literal: true

RSpec.feature "Add a Hearing Day", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "Verify Initial Modal State And Basic Errors" do
    scenario "When opening modal verify initial fields present" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
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
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
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
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      click_dropdown(index: "C", text: "Central")
      expect(page).to have_content("Select VLJ (Optional)", wait: 30)
      expect(page).not_to have_content("Select Regional Office (RO)")
      expect(page).to have_content("Select Hearing Coordinator (Optional)")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
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

  context "When adding a Central Office Hearing" do
    let!(:hearing_day) do
      create(:hearing_day, scheduled_for: Date.new(2019, 8, 14))
    end

    scenario "Hearing room 2 is already booked" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      fill_in "hearingDate", with: "08142019"
      click_dropdown(index: "C", text: "Central")
      find("button", text: "Confirm").click
      expect(page).to have_content(COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_TITLE % "08/14/2019")
      expect(page).to have_content(COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_DETAIL)
    end
  end

  context "Add a Video Hearing Day" do
    scenario "When opening modal and selecting Central Office verify correct fields present" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Date").click
      expect(page).to have_content("Add Hearing Day")
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Select Regional Office (RO)", wait: 30)
      expect(page).to have_content("Select VLJ (Optional)")
      expect(page).to have_content("Select Hearing Coordinator (Optional)")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
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
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
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

  context "has a judge and coordinator to select from the dropdown" do
    let!(:judge) do
      judge = create(:user)
      create(:staff, :judge_role, sdomainid: judge.css_id)
      judge
    end
    let!(:coordinator) do
      coordinator = create(:user)
      create(:staff, :hearing_coordinator, sdomainid: coordinator.css_id)
      coordinator
    end

    before do
      visit "hearings/schedule"
      find("button", text: "Add Hearing Date").click
      click_dropdown(index: "V", text: "Video")
    end

    scenario "select a vlj from the dropdown works" do
      click_dropdown(name: "vlj", text: judge.full_name, wait: 30)
      expect(page).to have_content(judge.full_name)
    end

    scenario "select a coordinator from the dropdown works" do
      click_dropdown(name: "coordinator", text: coordinator.full_name, wait: 30)
      expect(page).to have_content(coordinator.full_name)
    end
  end
end
