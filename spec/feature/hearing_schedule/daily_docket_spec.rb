# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket" do
  context "Daily docket with one legacy hearing" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }
    let!(:hearing_day) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             regional_office: "RO18",
             scheduled_for: Date.new(2019, 4, 15))
    end
    let!(:hearing_day_two) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             regional_office: "RO18",
             scheduled_for: hearing_day.scheduled_for + 10.days)
    end

    let!(:veteran) { create(:veteran, file_number: "123456789") }
    let!(:vacols_case) { create(:case, bfcorlid: "123456789S") }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
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
    let!(:legacy_hearing) { create(:legacy_hearing, vacols_id: case_hearing.hearing_pkseq, appeal: legacy_appeal) }
    let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }

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
  end

  context "Daily docket with one AMA hearing" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }
    let!(:hearing) { create(:hearing, :with_tasks) }
    let!(:postponed_hearing_day) { create(:hearing_day, scheduled_for: Date.new(2019, 3, 3)) }

    scenario "User can update fields" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      fill_in "Notes", with: "This is a note about the hearing!"
      find("label", text: "9:00 am").click
      find("label", text: "Transcript Requested").click
      click_button("Save")
      click_dropdown(name: "#{hearing.external_id}-disposition", text: "No Show")
      click_button("Confirm")

      expect(page).to have_content("You have successfully updated", wait: 30)
      expect(page).to have_content("No Show", wait: 30)
      expect(page).to have_content("This is a note about the hearing!", wait: 30)
      expect(find_field("Transcript Requested", visible: false)).to be_checked
      expect(find_field("9:00 am", visible: false)).to be_checked
    end
  end

  context "Daily docket with an uneditable dispositon" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }
    let!(:hearing) { create(:hearing) }
    let!(:hearing_task_association) do
      create(:hearing_task_association, hearing: hearing, hearing_task: create(:hearing_task, appeal: hearing.appeal))
    end
    let!(:disposition_task) do
      create(:disposition_task,
             parent: hearing_task_association.hearing_task,
             appeal: hearing.appeal,
             status: Constants.TASK_STATUSES.completed)
    end

    scenario "User cannot update disposition" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.external_id}-disposition")).to have_css(".is-disabled")
    end
  end

  context "Daily docket for RO view user" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["RO ViewHearSched"]) }
    let!(:hearing) { create(:hearing, :with_tasks) }

    scenario "User can only update notes" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(page).to_not have_content("Edit Hearing Day")
      expect(page).to_not have_content("Lock Hearing Day")
      expect(page).to_not have_content("Hearing Details")
      expect(page).to have_field("Transcript Requested", disabled: true, visible: false)
      expect(find(".dropdown-#{hearing.external_id}-disposition")).to have_css(".is-disabled")
      fill_in "Notes", with: "This is a note about the hearing!"
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("This is a note about the hearing!")
    end
  end

  context "Daily docket for VSO user" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["VSO"]) }
    let!(:hearing) { create(:hearing, :with_tasks) }
    let!(:vso) { create(:vso) }
    let!(:track_veteran_task) { create(:track_veteran_task, appeal: hearing.appeal, assigned_to: vso) }

    scenario "User has no assigned hearings" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      expect(page).to_not have_content("Edit Hearing Day")
      expect(page).to_not have_content("Lock Hearing Day")
      expect(page).to_not have_content("Hearing Details")
    end
  end

  context "Daily docket for Judge user" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }
    let!(:hearing_day) { create(:hearing_day, judge: current_user) }
    let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }
    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: current_user, hearing_day: hearing_day) }

    scenario "User has hearing prep fields" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

      expect(page).to have_css(".dropdown-#{hearing.external_id}-aod")
      expect(page).to have_css(".dropdown-#{hearing.external_id}-aodReason")
      expect(page).to have_css(".dropdown-#{legacy_hearing.external_id}-holdOpen")

      click_dropdown(name: "#{legacy_hearing.external_id}-holdOpen", index: 0)
      find(".checkbox-wrapper-checkbox-prepped-#{legacy_hearing.external_id}").click
      find("label", text: "Transcript Requested", match: :first).click
      find("textarea", id: "#{legacy_hearing.external_id}-notes", match: :first)
        .fill_in(with: "This is a note about the hearing!")
      click_button("Save")

      expect(page).to have_content("You have successfully updated")

      find("label", text: "Yes, Waive 90 Day Hold", match: :first).click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
    end

    context "and hearings are not assigned to judge" do
      let!(:hearing_day) { create(:hearing_day, judge: create(:user)) }
      let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: create(:user), hearing_day: hearing_day) }

      scenario "no hearings are shown" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

        expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      end
    end
  end
end
