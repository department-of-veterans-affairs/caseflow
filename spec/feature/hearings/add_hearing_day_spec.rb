# frozen_string_literal: true

RSpec.feature "Add a Hearing Day", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "Verify Initial State And Basic Errors" do
    scenario "When adding a hearing day verify initial fields present" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click

      # Required Fields
      expect(page).to have_content("Add a Hearing Day")
      expect(page).to have_content("Docket Date")
      expect(page).to have_content("Type of Docket")

      # Optional Room Assignment (Central and Video only)
      expect(page).to have_content("Assign a Board hearing room")

      # Dropdowns should not be visible until selecting a Docket Type
      expect(page.has_no_content?("Regional Office (RO)")).to eq(true)
      expect(page.has_no_content?("VLJ")).to eq(true)
      expect(page.has_no_content?("Hearing Coordinator")).to eq(true)
      expect(page.has_no_content?("Number of Time Slots")).to eq(true)
      expect(page.has_no_content?("Length of Time Slots")).to eq(true)
      expect(page.has_no_content?("Start Time of Slots")).to eq(true)
      expect(page.has_no_content?("Preview Time Slots")).to eq(true)
      expect(page).not_to have_selector(".cf-help-divider")

      # Hearing Notes should always be present
      expect(page).to have_content("Notes")
    end

    scenario "Add Hearing Day but do not fill form, expect error" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Cannot create a New Hearing Day")
      expect(page).to have_content("Please make sure you have entered a Hearing Date")
    end
  end

  context "When adding a Central Office Hearing" do
    let!(:hearing_day) do
      create(:hearing_day, scheduled_for: Date.new(2019, 8, 14))
    end

    scenario "When adding a hearing day and selecting Central Office verify correct fields present" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click

      # Required form fields
      expect(page).to have_content("Add a Hearing Day")
      click_dropdown(index: "C", text: "Central")
      expect(page).to have_content("VLJ", wait: 30)
      expect(page).to have_content("Hearing Coordinator")

      # Form fields not Present
      expect(page.has_no_content?("Regional Office (RO)")).to eq(true)
      expect(page.has_no_content?("Number of Time Slots")).to eq(true)
      expect(page.has_no_content?("Length of Time Slots")).to eq(true)
      expect(page.has_no_content?("Start Time of Slots")).to eq(true)
      expect(page.has_no_content?("Preview Time Slots")).to eq(true)
      expect(page).not_to have_selector(".cf-help-divider")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      fill_in "hearingDate", with: "01152019"
      click_dropdown(index: "C", text: "Central")
      expect(page).to have_content("VLJ", wait: 30)
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes", with: "Test notes."
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("You have successfully added Hearing Day 01/15/2019", wait: 30)
    end

    scenario "Hearing room 2 is already booked" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      fill_in "hearingDate", with: "08142019"
      click_dropdown(index: "C", text: "Central")
      find(".cf-form-checkbox").find("label[for=roomRequired]").click
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content(COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_TITLE % "08/14/2019")
      expect(page).to have_content(COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_DETAIL)
    end
  end

  context "When adding a Video Hearing Day" do
    scenario "When adding a hearing day and selecting Video verify correct fields present" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      click_dropdown(index: "V", text: "Video")

      # Confirm presence of available times
      expect(page).to have_content("Available Times")

      # Confirm fields present
      expect(page).to have_content("Regional Office (RO)", wait: 30)
      expect(page).to have_content("VLJ")
      expect(page).to have_content("Hearing Coordinator")

      # Confirm fields not present
      expect(page.has_no_content?("Number of Time Slots")).to eq(true)
      expect(page.has_no_content?("Length of Time Slots")).to eq(true)
      expect(page.has_no_content?("Start Time of Slots")).to eq(true)
      expect(page.has_no_content?("Preview Time Slots")).to eq(true)
      expect(page).not_to have_selector(".cf-help-divider")
    end

    scenario "Fill out all fields and confirm to save" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      fill_in "hearingDate", with: "04152019"
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Regional Office (RO)", wait: 30)
      dropdowns = page.all(".cf-select__control")
      dropdowns[1].click
      dropdowns[1].sibling(".cf-select__menu").find("div .cf-select__option", text: "Atlanta, GA").click
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes", with: "Test notes."
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("You have successfully added Hearing Day 04/15/2019", wait: 30)
    end

    scenario "Leave Regional Office without a selection, expect error" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Add a Hearing Day")
      fill_in "hearingDate", with: "04152019"
      click_dropdown(index: "V", text: "Video")
      expect(page).to have_content("Regional Office (RO)", wait: 30)
      fill_in "vlj", with: "Sallie L Anderson"
      fill_in "coordinator", with: "Casimir R Funk"
      fill_in "Notes", with: "Test notes."
      find("button", text: "Add Hearing Day").click
      expect(page).to have_content("Hearing type is a Video hearing")
      expect(page).to have_content("Please make sure you select a Regional Office")
    end

    context "When adding a full or half day dockets" do
      shared_examples "adding full or half day dockets" do
        scenario "fill out form and submit successfully" do
          visit "hearings/schedule"
          find("button", text: "Add Hearing Day").click
          fill_in "hearingDate", with: "04152019"
          click_dropdown(index: "V", text: "Video")

          # Confirm presence of available times
          expect(page).to have_content("Available Times")
          radio_choices = page.all(".cf-form-radio-option")
          expect(radio_choices[0]).to have_content("Full-Day AM & PM (10 slots at 8:30 AM & 12:30 PM Eastern)")
          expect(radio_choices[1]).to have_content("Half-Day AM (5 slots at 8:30 AM Eastern")
          expect(radio_choices[2]).to have_content("Half-Day PM (5 slots at 12:30 PM Eastern")

          expect(page).to have_content("Regional Office (RO)", wait: 30)
          dropdowns = page.all(".cf-select__control")
          dropdowns[1].click
          dropdowns[1].sibling(".cf-select__menu").find("div .cf-select__option", text: "Los Angeles, CA").click

          radio_choices = page.all(".cf-form-radio-option > label")
          expect(radio_choices[0]).to have_content("Full-Day AM & PM (10 slots at 8:30 AM & 12:30 PM Pacific)")
          expect(radio_choices[1]).to have_content("Half-Day AM (5 slots at 8:30 AM Pacific / 11:30 AM Eastern)")
          expect(radio_choices[2]).to have_content("Half-Day PM (5 slots at 12:30 PM Pacific / 3:30 PM Eastern)")

          radio_choices[choice].click
          find("button", text: "Add Hearing Day").click
          expect(page).to have_content("You have successfully added Hearing Day 04/15/2019", wait: 30)

          # Verify db values
          expect(HearingDay.last.reload.total_slots).to eq(total_slots)
          expect(HearingDay.last.first_slot_time).to eq(first_slot_time)
          expect(HearingDay.last.begins_at).to eq(begins_at)
        end
      end

      context "Full day" do
        let(:choice) { 0 }
        let(:total_slots) { HearingDay::SLOTS_BY_REQUEST_TYPE["V"][:default] }
        let(:first_slot_time) { nil }
        let(:begins_at) { nil }
        include_examples "adding full or half day dockets"
      end

      context "Half day AM" do
        let(:choice) { 1 }
        let(:total_slots) { 5 }
        let(:first_slot_time) { "11:30" }
        let(:begins_at) { "2019-04-15T11:30:00-04:00" }
        include_examples "adding full or half day dockets"
      end

      context "Half day PM" do
        let(:choice) { 2 }
        let(:total_slots) { 5 }
        let(:first_slot_time) { "03:30" }
        let(:begins_at) { "2019-04-15T03:30:00-04:00" }
        include_examples "adding full or half day dockets"
      end
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
      find("button", text: "Add Hearing Day").click
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

  context "When adding a Virtual Hearing day" do
    before { FeatureToggle.enable!(:national_vh_queue) }
    after { FeatureToggle.disable!(:national_vh_queue) }

    scenario "Adds a virtual hearing day" do
      step "Adding a hearing day and selecting Virtual presents correct fields" do
        visit "hearings/schedule"
        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
        find("button", text: "Add Hearing Day").click
        expect(page).to have_content("Add a Hearing Day")
        click_dropdown(index: "R", text: "Virtual")
        expect(page).to have_content("Regional Office (RO)", wait: 30)

        expect(page).to have_content("VLJ")
        expect(page).to have_content("Hearing Coordinator")
        expect(page).to have_field("Assign a Board hearing room", disabled: true, visible: false)
        expect(find_field("Assign a Board hearing room", disabled: true, visible: false)).not_to be_checked

        # Time slot fields should only be present after selecting a Regional Office
        expect(page.has_no_content?("Number of Time Slots")).to eq(true)
        expect(page.has_no_content?("Length of Time Slots")).to eq(true)
        expect(page.has_no_content?("Start Time of Slots")).to eq(true)
        expect(page.has_no_content?("Preview Time Slots")).to eq(true)
        expect(page).not_to have_selector(".cf-help-divider")
      end

      step "Leave Hearing Date without a selection, expect error" do
        fill_in "vlj", with: "Sallie L Anderson"
        fill_in "coordinator", with: "Casimir R Funk"
        fill_in "Notes", with: "Test notes."
        find("button", text: "Add Hearing Day").click
        expect(page).to have_content("Please make sure you have entered a Hearing Date")
      end

      step "Choose a Regional office, expect time slot preview" do
        # Select the hearing Date
        fill_in "hearingDate", with: "01012021"

        # Select a Regional Office
        dropdowns = page.all(".cf-select__control")
        dropdowns[1].click
        dropdowns[1].sibling(".cf-select__menu").find("div .cf-select__option", text: "Atlanta, GA").click

        # Expect the Time Slot details and preview
        expect(page).to have_selector(".cf-help-divider")
        expect(page).to have_content("Number of Time Slots")
        expect(page).to have_content("Length of Time Slots")
        expect(page).to have_content("Start Time of Slots")
        expect(page).to have_content("Preview Time Slots")

        # Expect the number of slots corresponds to the default selected number of slots (8)
        timeslots = page.all(".time-slot-button")
        expect(timeslots.count).to eq(8)
        expect(timeslots[0]).to have_content("8:30 AM")
        expect(timeslots[1]).to have_content("9:30 AM")
      end

      step "Update number of slots, expect Time Slot Preview update" do
        dropdowns = page.all(".cf-select__control")
        dropdowns[4].click
        dropdowns[4].sibling(".cf-select__menu").find("div .cf-select__option", text: 4).click

        # Expect the number of slots corresponds to the selected number of slots
        timeslots = page.all(".time-slot-button")
        expect(timeslots.count).to eq(4)
      end

      step "Update length of slots, expect Time Slot Preview update" do
        dropdowns = page.all(".cf-select__control")
        dropdowns[5].click
        dropdowns[5].sibling(".cf-select__menu").find("div .cf-select__option", text: "30 minutes").click

        # Expect the number of slots corresponds to the selected number of slots
        timeslots = page.all(".time-slot-button")
        expect(timeslots[0]).to have_content("8:30 AM")
        expect(timeslots[1]).to have_content("9:00 AM")
      end

      step "Update start time of slots, expect Time Slot Preview update" do
        # Change the length of time slots back to 60
        dropdowns = page.all(".cf-select__control")
        dropdowns[5].click
        dropdowns[5].sibling(".cf-select__menu").find("div .cf-select__option", text: "60 minutes").click

        # Change the hearing start time
        dropdowns = page.all(".cf-select__control")
        dropdowns[6].click
        dropdowns[6].sibling(".cf-select__menu").find("div .cf-select__option", text: "8:45 AM").click

        # Expect the number of slots corresponds to the selected number of slots
        timeslots = page.all(".time-slot-button")
        expect(timeslots[0]).to have_content("8:45 AM")
        expect(timeslots[1]).to have_content("9:45 AM")
      end

      step "Fill out all fields and confirm to save" do
        find("button", text: "Add Hearing Day").click
        expect(page).to have_content("You have successfully added Hearing Day 01/01/2021", wait: 30)
      end
    end
  end
end
