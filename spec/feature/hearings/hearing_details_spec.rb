# frozen_string_literal: true

RSpec.feature "Hearing Details", :all_dbs do
  let(:user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }
  let!(:coordinator) { create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG") }
  let!(:vlj) { create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO") }
  let(:hearing) { create(:hearing, :with_tasks, regional_office: "C", scheduled_time: "9:30AM") }
  let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name }
  let(:virtual_hearing_alert) do
    COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end

  let(:pre_loaded_veteran_email) { hearing.appeal.veteran.email_address }
  let(:pre_loaded_rep_email) { hearing.appeal.representative_email_address }
  let(:fill_in_veteran_email) { "new@email.com" }
  let(:fill_in_veteran_tz) { "America/New_York" }
  let(:fill_in_rep_email) { "rep@testingEmail.com" }
  let(:fill_in_rep_tz) { "America/Chicago" }
  let(:pexip_url) { "fake.va.gov" }

  shared_examples "always updatable fields" do
    scenario "user can select judge, hearing room, hearing coordinator, and add notes" do
      # wait until the label displays before trying to interact with the dropdowns
      find("div", class: "dropdown-judgeDropdown", text: COPY::DROPDOWN_LABEL_JUDGE)
      find("div", class: "dropdown-hearingCoordinatorDropdown", text: COPY::DROPDOWN_LABEL_HEARING_COORDINATOR)
      find("div", class: "dropdown-hearingRoomDropdown", text: COPY::DROPDOWN_LABEL_HEARING_ROOM)

      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingRoomDropdown", index: 0, wait: 30)

      if hearing.is_a?(Hearing)
        find("label", text: "Yes, Waive 90 Day Evidence Hold").click
      end

      fill_in "Notes", with: generate_words(10)

      # Save the edited fields
      click_button("Save")

      expect(page).to have_content(expected_alert)
    end
  end

  shared_examples "non-virtual hearing type conversion" do
    scenario "user can convert hearing type to virtual" do
      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

      fill_in "Veteran Email (for these notifications only)", with: fill_in_veteran_email
      fill_in "POA/Representative Email (for these notifications only)", with: fill_in_veteran_email
      click_button("button-Save")

      expect(page).to have_no_content(expected_alert)
      expect(page).to have_content(virtual_hearing_alert)
    end
  end

  shared_examples "all hearing types" do
    context "when type is Video" do
      before do
        hearing.hearing_day.update!(regional_office: "RO06", request_type: "V")
      end

      include_examples "always updatable fields"
      include_examples "non-virtual hearing type conversion"
    end

    context "when type is Central" do
      before do
        hearing.hearing_day.update!(regional_office: nil, request_type: "C")
      end

      include_examples "always updatable fields"
      include_examples "non-virtual hearing type conversion"
    end

    context "when type is Virtual" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          status: :active,
          hearing: hearing,
          appellant_email: "existing_veteran_email@caseflow.gov",
          appellant_email_sent: true,
          judge_email: "existing_judge_email@caseflow.gov",
          judge_email_sent: true,
          representative_email: nil
        )
      end

      include_examples "always updatable fields"
    end
  end

  context "with unauthorized user role (non-hearings management)" do
    let!(:current_user) { User.authenticate!(user: user) }

    scenario "Fields are not editable" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_field("Notes", disabled: true)
    end
  end

  context "with authorized user role" do
    let!(:current_user) do
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
    end
    let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name }

    context "when hearing is AMA" do
      before do
        visit "hearings/" + hearing.external_id.to_s + "/details"
      end

      include_examples "all hearing types"

      scenario "user can update transcription fields" do
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

      context "when hearing already has transcription details" do
        let!(:transcription) do
          create(
            :transcription,
            hearing: hearing,
            problem_type: Constants.TRANSCRIPTION_PROBLEM_TYPES.POOR_AUDIO,
            requested_remedy: Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING
          )
        end

        # This test ensures that a bug related to sending partial form data is fixed.
        #   See: https://github.com/department-of-veterans-affairs/caseflow/issues/14130
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

    context "when hearing is Legacy" do
      before do
        visit "hearings/" + hearing.external_id.to_s + "/details"
      end

      include_examples "all hearing types"

      scenario "user cannot update transcription fields" do
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
end
