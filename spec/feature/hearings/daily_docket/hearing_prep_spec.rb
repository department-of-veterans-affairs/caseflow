# frozen_string_literal: true

RSpec.feature "Hearing Schedule Daily Docket for Hearing Prep", :all_dbs do
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }
  let!(:hearing_day) { create(:hearing_day, judge: current_user) }

  context "with a legacy hearing" do
    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: current_user, hearing_day: hearing_day) }

    scenario "User can update hearing prep fields" do
      visit "hearings/schedule/docket/" + legacy_hearing.hearing_day.id.to_s

      expect(page).to have_button("Print all Hearing Worksheets", disabled: false)
      click_dropdown(name: "#{legacy_hearing.external_id}-disposition", index: 0)
      click_button("Confirm")
      expect(page).to have_content("You have successfully updated")

      click_dropdown(name: "#{legacy_hearing.external_id}-aod", text: "Granted")
      click_dropdown(name: "#{legacy_hearing.external_id}-holdOpen", index: 0)
      find("label", text: "Transcript Requested", match: :first).click
      find("textarea", id: "#{legacy_hearing.external_id}-notes", match: :first)
        .fill_in(with: "This is a note about the hearing!")
      click_button("Save", match: :first)

      expect(page).to have_content("You have successfully updated")
    end
  end

  context "with a legacy and AMA hearing" do
    let!(:hearing_day) { create(:hearing_day, judge: create(:user)) }
    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: create(:user), hearing_day: hearing_day) }
    let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }

    scenario "no hearings are shown" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

      expect(page).to have_content(COPY::HEARING_SCHEDULE_DOCKET_JUDGE_WITH_NO_HEARINGS)
    end
  end

  context "with an AMA hearing" do
    let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }
    let!(:person) { Person.find_by(participant_id: hearing.appeal.appellant.participant_id) }

    scenario "User can update hearing prep fields" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

      click_dropdown(name: "#{hearing.external_id}-disposition", index: 0)
      click_button("Confirm")
      expect(page).to have_content("You have successfully updated")

      find("label", text: "Transcript Requested", match: :first).click
      find("textarea", id: "#{hearing.external_id}-notes", match: :first)
        .fill_in(with: "This is a note about the hearing!")

      find("label", text: "Yes, Waive 90 Day Hold", match: :first).click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
    end

    context "with an existing denied AOD motion made by another judge" do
      before do
        AdvanceOnDocketMotion.create!(
          user_id: create(:user).id,
          person_id: person.id,
          granted: false,
          reason: Constants.AOD_REASONS.age
        )
      end

      scenario "judge can overwrite previous AOD motion" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
        click_dropdown(name: "#{hearing.external_id}-aod", text: "Granted")
        click_dropdown(name: "#{hearing.external_id}-aodReason", text: "Financial Distress")
        click_button("Save")

        expect(page).to have_content("There is a prior AOD decision")
        click_button("Confirm")

        expect(page).to have_content("You have successfully updated")
      end
    end

    context "with an existing AOD motion made by same judge" do
      before do
        AdvanceOnDocketMotion.create!(
          user_id: current_user.id,
          person_id: person.id,
          granted: true,
          reason: Constants.AOD_REASONS.serious_illness
        )
      end

      scenario "judge can overwrite AOD motion" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
        click_dropdown(name: "#{hearing.external_id}-aod", text: "Denied")
        click_dropdown(name: "#{hearing.external_id}-aodReason", text: "Financial Distress")
        click_button("Save")

        expect(page).to have_content("You have successfully updated")
        expect(AdvanceOnDocketMotion.count).to eq(1)
        judge_motion = AdvanceOnDocketMotion.first
        expect(judge_motion.granted).to eq(false)
        expect(judge_motion.reason).to eq(Constants.AOD_REASONS.financial_distress)
      end
    end

    context "with no existing AOD motion" do
      scenario "judge can create a new AOD motion" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
        click_dropdown(name: "#{hearing.external_id}-aod", text: "Granted")
        click_button("Save")
        expect(page).to have_content("Please select an AOD reason")
        click_dropdown(name: "#{hearing.external_id}-aodReason", text: "Financial Distress")
        click_button("Save")

        expect(page).to have_content("You have successfully updated")
        expect(AdvanceOnDocketMotion.count).to eq(1)
        judge_motion = AdvanceOnDocketMotion.first
        expect(judge_motion.granted).to eq(true)
        expect(judge_motion.reason).to eq(Constants.AOD_REASONS.financial_distress)
      end
    end
  end
end
