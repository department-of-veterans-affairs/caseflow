# frozen_string_literal: true

RSpec.feature "Hearing Schedule Daily Docket", :all_dbs do
  let(:user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  before do
    create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
    create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
  end

  context "Hearing details is not editable for a non-hearings management user" do
    let!(:current_user) { User.authenticate!(user: user) }
    let!(:hearing) { create(:hearing, :with_tasks) }

    scenario "Fields are not editable" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_field("Notes", disabled: true)
    end
  end

  context "Hearing details for AMA hearing" do
    let!(:current_user) do
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
    end
    let!(:hearing) { create(:hearing, :with_tasks) }
    let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name }

    scenario "User can update fields" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      # wait until the label displays before trying to interact with the dropdown
      find("div", class: "dropdown-judgeDropdown", text: COPY::DROPDOWN_LABEL_JUDGE)
      click_dropdown(name: "judgeDropdown", index: 0)

      find("div", class: "dropdown-hearingCoordinatorDropdown", text: COPY::DROPDOWN_LABEL_HEARING_COORDINATOR)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0)

      find("div", class: "dropdown-hearingRoomDropdown", text: COPY::DROPDOWN_LABEL_HEARING_ROOM)
      click_dropdown(name: "hearingRoomDropdown", index: 0)

      find("label", text: "Yes, Waive 90 Day Evidence Hold").click

      fill_in "Notes", with: generate_words(10)
      fill_in "taskNumber", with: "123456789"
      click_dropdown(name: "transcriber", index: 1)
      fill_in "sentToTranscriberDate", with: "04012019"
      fill_in "expectedReturnDate", with: "04022019"
      fill_in "uploadedToVbmsDate", with: "04032019"

      click_dropdown(name: "problemType", index: 1)
      fill_in "problemNoticeSentDate", with: "04042019"
      find(
        ".cf-form-radio-option",
        text: Constants.TRANSCRIPTION_REQUESTED_REMEDIES.PROCEED_WITHOUT_TRANSCRIPT
      ).click

      find("label", text: "Yes, Transcript Requested").click
      fill_in "copySentDate", with: "04052019"

      click_button("Save")

      expect(page).to have_content(expected_alert)
    end

    context "has transcription details" do
      let!(:transcription) do
        create(
          :transcription,
          hearing: hearing,
          problem_type: Constants.TRANSCRIPTION_PROBLEM_TYPES.POOR_AUDIO,
          requested_remedy: Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING
        )
      end

      # This test ensures that a bug related to sending partial form data is fixed.
      #
      #   See: https://github.com/department-of-veterans-affairs/caseflow/issues/14130
      #
      scenario "can update fields without side-effects to transcription" do
        visit "hearings/#{hearing.external_id}/details"

        step "ensure page has existing transcription details" do
          expect(
            page.find(".dropdown-problemType .cf-select__value-container")
          ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.POOR_AUDIO)
          expect(
            find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
          ).to be_checked
        end

        step "changing only problem type preserves already populated fields" do
          click_dropdown(name: "problemType", index: 0)
          click_button("Save")

          expect(page).to have_content(expected_alert)

          visit "hearings/#{hearing.external_id}/details"

          expect(
            page.find(".dropdown-problemType .cf-select__value-container")
          ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.NO_AUDIO)
          expect(
            find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
          ).to be_checked
          expect(Transcription.count).to be(2)
        end

        step "changing notes preserves already populated fields and doesn't create new transcription" do
          fill_in "Notes", with: "Test Notes Test Notes"
          click_button("Save")

          expect(page).to have_content(expected_alert)

          visit "hearings/#{hearing.external_id}/details"

          expect(page).to have_content("Test Notes Test Notes")
          expect(
            page.find(".dropdown-problemType .cf-select__value-container")
          ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.NO_AUDIO)
          expect(
            find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
          ).to be_checked
          expect(Transcription.count).to be(2)
        end
      end
    end
  end

  context "Hearing details for Legacy hearing" do
    let!(:current_user) do
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
      FeatureToggle.enable!(:schedule_virtual_hearings)
    end

    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, regional_office: "RO06") }
    let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % legacy_hearing.appeal.veteran.name }
    let(:virtual_hearing_alert) do
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % legacy_hearing.appeal.veteran.name
    end

    scenario "User can edit Judge and change virtual hearings" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"
      expect(page).to have_field("judge-dropdown", disabled: false)
      expect(page).to have_field("hearing-coordinator-dropdown", disabled: false)
      expect(page).to have_field("hearing-room-dropdown", disabled: false)
      expect(page).to have_field("Notes", disabled: false)
      expect(page).to have_no_selector("label", text: "Yes, Waive 90 Day Evidence Hold")

      click_dropdown(name: "hearingType", index: 0)
      fill_in "appellant-email", with: "email@testingEmail.com"
      fill_in "representative-email", with: "email@testingEmail.com"
      click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

      expect(page).to have_no_content(expected_alert)
      expect(page).to have_content(virtual_hearing_alert)
    end

    scenario "User can select judge, hearing room, hearing coordinator, and add notes" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingRoomDropdown", index: 0, wait: 30)

      fill_in "Notes", with: generate_words(10)

      click_button("Save")
      expect(page).to have_content(expected_alert)
    end

    scenario "User can not edit transcription" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      expect(page).to have_no_field("taskNumber")
      expect(page).to have_no_field("transcriber")
      expect(page).to have_no_field("sentToTranscriberDate")
      expect(page).to have_no_field("expectedReturnDate")
      expect(page).to have_no_field("uploadedToVbmsDate")
      expect(page).to have_no_field("problemType")
      expect(page).to have_no_field("problemNoticeSentDate")
      expect(page).to have_no_field("requestedRemedy")
      expect(page).to have_no_field("copySentDate")
      expect(page).to have_no_field("copyRequested")
    end
  end
end
