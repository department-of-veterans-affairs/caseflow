# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  before do
    FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
    HearingsManagement.singleton.add_user(hearing_coord)
    vso.add_user(vso_user)
  end
  after { FeatureToggle.disable!(:schedule_veteran_virtual_hearing) }
  let!(:appeal) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket, number_of_claimants: 1)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video,
              veteran_is_not_claimant: true)
    a
  end
  let!(:hearing_day) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 14.days, regional_office: "RO63") }
  let!(:hearing_day2) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days, regional_office: "RO63") }
  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
  let!(:vso_user) { create(:user, :vso_role, email: "DefinitelyNotNull@All.com") }
  let!(:hearing_coord) { create(:user, roles: ["Edit HearSched", "Build HearSched"]) }
  let!(:poa) { create(:bgs_power_of_attorney, :with_name_cached, appeal: appeal) }

  context "When appeal has no scheduled hearings" do
    scenario "convert to virtual link appears and leads to task form" do
      step "navigate to the VSO Form" do
        User.authenticate!(user: vso_user)
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Video")
        click_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
      end

      step "verify pre-population of fields" do
        expect(page).to have_content("Convert Hearing To Virtual")

        ["#{appeal.appellant.first_name} #{appeal.appellant.last_name}",
         appeal.appellant.email_address,
         poa.representative_name,
         poa.representative_type,
         "Pacific Time (US & Canada)",
         "Eastern Time (US & Canada)",
         vso_user.email].each do |field_value|
          expect(page).to have_content(field_value)
        end
      end

      step "test form validation and submit it" do
        # Check if button is disabled on page load
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Affirm checkboxes first to test other fields
        click_label("Affirm Permission")
        click_label("Affirm Access")

        # Check if buttone remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Fill out email field and expect validation message on invalid email
        fill_in "Appellant Email", with: "appellant@test"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)
        fill_in "Appellant Email", with: "appellant@test.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)

        # Check if button remains disabled
        expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

        # Fill out confirm email field and expect validation message on unmatched email
        fill_in "Confirm Appellant Email", with: "appellant@not-matching"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
        fill_in "Confirm Appellant Email", with: "appellant@test.com"
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

        fill_in "Veteran Email", with: "appellant@test.com"
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

  context "When appeal has no scheduled hearings" do
    scenario "no link appears in hearing section" do
      step "navigate to the VSO Form" do
        appeal.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.virtual)
        User.authenticate!(user: vso_user)
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Virtual")
        expect(page).not_to have_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
      end
    end
  end

  context "When appeal has a scheduled hearing in over 11 days" do
    scenario "convert to virtual link appears and leads to hearing form" do
      step "select from dropdown" do
        User.authenticate!(user: hearing_coord)
        visit "queue/appeals/#{appeal.uuid}"
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
      end

      step "fill in form" do
        fill_in "Notes", with: "asfsefdsfdf"
        click_dropdown(name: "regionalOffice", index: 1)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 1)
        click_dropdown(name: "optionalHearingTime0", index: 0)
        click_button(text: "Schedule")
      end
      step "navigate to the hearings form" do
        appeal = Appeal.last
        User.authenticate!(user: vso_user)
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Video")
        expect(page).to have_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
        click_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
        expect(page).to have_current_path("/hearings/#{appeal.hearings.first.uuid}/details")
      end
    end
  end

  context "When hearing is within 11 days of scheduled time" do
    scenario "info alert appears instead of link" do
      step "select from dropdown" do
        User.authenticate!(user: hearing_coord)
        visit "queue/appeals/#{appeal.uuid}"
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
      end

      step "fill in form" do
        fill_in "Notes", with: "asfsefdsfdf"
        click_dropdown(name: "regionalOffice", index: 1)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 0)
        click_dropdown(name: "optionalHearingTime0", index: 0)
        click_button(text: "Schedule")
      end

      step "vso user" do
        appeal = Appeal.last
        User.authenticate!(user: vso_user)
        visit "queue/appeals/#{appeal.uuid}"

        expect(page).not_to have_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
        expect(page).to have_content(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)
      end
    end
  end
end
