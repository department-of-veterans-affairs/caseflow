# frozen_string_literal: true

feature "Hearing Schedule Daily Docket for Build HearSched", :all_dbs do
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  context "Daily docket with one legacy hearing" do
    let!(:hearing_day) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             regional_office: "RO18",
             scheduled_for: Date.new(2020, 4, 15))
    end

    let!(:vacols_case) { create(:case, bfcorlid: "123456789S") }
    let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: vacols_case) }
    let!(:hearing_location) do
      create(:available_hearing_locations,
             appeal_id: legacy_appeal.id,
             appeal_type: "LegacyAppeal",
             city: "Holdrege",
             state: "NE",
             distance: 0,
             facility_type: "va_health_facility")
    end

    let!(:case_hearing) { create(:case_hearing, vdkey: hearing_day.id, folder_nr: legacy_appeal.vacols_id) }
    let!(:legacy_hearing) { create(:legacy_hearing, case_hearing: case_hearing, appeal: legacy_appeal) }
    let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }

    scenario "address and poa info from BGS is displayed on docket page" do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      expect(page).to have_content FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1
      expect(page).to have_content(
        [
          FakeConstants.BGS_SERVICE.DEFAULT_CITY,
          FakeConstants.BGS_SERVICE.DEFAULT_STATE,
          FakeConstants.BGS_SERVICE.DEFAULT_ZIP
        ].join(" ")
      )

      expect(page).to have_content FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME
    end

    scenario "User can update fields" do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      click_dropdown(name: "#{legacy_hearing.external_id}-disposition", index: 1)
      click_button("Confirm")
      expect(page).to have_content("You have successfully updated")
      expect(page).to_not have_content("Finding hearing locations", wait: 30)
      click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
      fill_in "Notes", with: "This is a note about the hearing!"
      find("label", text: "8:30 am").click
      find("label", text: "Transcript Requested").click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Show")
      expect(page).to have_content("This is a note about the hearing!")
      expect(find_field("Transcript Requested", visible: false)).to be_checked
      expect(find_field("8:30", visible: false)).to be_checked
    end

    scenario "User can see paper_case notification" do
      visit "hearings/schedule/docket/" + legacy_hearing.hearing_day.id.to_s
      expect(page).to have_content(COPY::IS_PAPER_CASE)
    end
  end

  context "Daily Docket with one AMA hearing" do
    let!(:hearing) { create(:hearing, :with_tasks) }
    let!(:postponed_hearing_day) { create(:hearing_day, scheduled_for: Date.new(2019, 3, 3)) }

    scenario "User can update fields", skip: "flake" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      find("textarea", id: "#{hearing.external_id}-notes").click.send_keys("This is a note about the hearing!")
      find("label", text: "9:00 am").click
      find("label", text: "Transcript Requested").click
      click_button("Save")
      expect(page).to have_content("You have successfully updated")

      click_dropdown({ text: "No Show" }, find("div", class: "dropdown-#{hearing.external_id}-disposition"))
      click_button("Confirm")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Show")
      expect(page).to have_content("This is a note about the hearing!", wait: 10) # flake
      expect(find_field("Transcript Requested", visible: false)).to be_checked
      expect(find_field("9:00 am", visible: false)).to be_checked
    end
  end

  context "Daily Docket with an uneditable disposition" do
    let!(:hearing) { create(:hearing) }
    let!(:hearing_task_association) do
      create(:hearing_task_association, hearing: hearing, hearing_task: create(:hearing_task, appeal: hearing.appeal))
    end
    let!(:disposition_task) do
      create(:assign_hearing_disposition_task,
             :completed,
             parent: hearing_task_association.hearing_task,
             appeal: hearing.appeal)
    end

    scenario "User cannot update disposition" do
      hearing_task_association.hearing_task.update(status: :in_progress)
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.external_id}-disposition")).to have_css(".is-disabled")
    end
  end
end
