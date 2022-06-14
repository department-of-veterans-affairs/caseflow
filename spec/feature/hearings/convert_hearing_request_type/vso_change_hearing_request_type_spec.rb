# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  let!(:appeal) { create(:appeal) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }
  let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }
  let!(:task) do
    create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task, assigned_to: vso)
  end

  before do
    vso.add_user(vso_user)
    User.authenticate!(user: vso_user)
  end

  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
  let!(:vso_user) { create(:user, :vso_role, email: "DefinitelyNotNull@All.com") }

  context "for VSO users" do
    scenario "Convert unscheduled appeal to Virtual hearing type" do
      step "navigate to the VSO Form" do
        visit "queue/appeals/#{appeal.uuid}"

        expect(page).to have_content(ChangeHearingRequestTypeTask.label)
        expect(ChangeHearingRequestTypeTask.count).to eq(1)

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label
        ).click
      end

      step "fill out the Form" do
        expect(page).to have_content("Convert Hearing To Virtual")

        # Check if button is disabled on page load
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Affirm checkboxes first to test other fields
        click_label("Affirm Permission")
        click_label("Affirm Access")

        # Check if buttone remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Fill out email field and expect validation message on invalid email
        fill_in "Veteran Email", with: "veteran@vetera"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)
        fill_in "Veteran Email", with: "veteran@veteran.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)

        # Check if button remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Fill out confirm email field and expect validation message on unmatched email
        fill_in "Confirm Veteran Email", with: "veteran@veteran"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
        fill_in "Confirm Veteran Email", with: "veteran@veteran.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

        # Set appellant tz to null
        click_dropdown(name: "appellantTz", index: 0)

        # Check if button remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Set rep tz to null
        click_dropdown(name: "representativeTz", index: 0)

        # Check if button remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Set appellant and rep timezones to something not null
        click_dropdown(name: "appellantTz", index: 1)
        click_dropdown(name: "representativeTz", index: 2)
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: false)

        # Alter original email to make sure that the confirm email validation picks up on the change.
        fill_in "Veteran Email", with: "valid@something-different.com"
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        fill_in "Veteran Email", with: "veteran@veteran.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

        # Convert button should now be enabled
        click_button("Convert Hearing To Virtual")
      end

      step "Confirm success message" do
        expect(page).to have_content(
          "You have successfully converted #{appeal.veteran_full_name}'s hearing to virtual"
        )
        expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)
      end
    end
  end
end
