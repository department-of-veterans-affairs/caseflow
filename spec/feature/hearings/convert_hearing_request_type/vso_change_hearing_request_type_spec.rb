# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  before do
    FeatureToggle.enable!(:schedule_veteran_virtual_hearing) 
    HearingsManagement.singleton.add_user(hearing_coord)
    vso.add_user(vso_user)
  end
  after { FeatureToggle.disable!(:schedule_veteran_virtual_hearing) }
  let!(:appeal) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
    a
  end
  let!(:hearing_day) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 14.days, regional_office: "RO63") }
  let!(:hearing_day2) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days, regional_office: "RO63") }
  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
  let!(:vso_user) { create(:user, :vso_role) }
  let!(:hearing_coord) { create(:user, roles: ["Edit HearSched", "Build HearSched"]) }

  context "When appeal has no scheduled hearings" do
    scenario "convert to virtual link appears and leads to task form" do
      step "navigate to the VSO Form" do
        User.authenticate!(user: vso_user)
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Video")
        expect(page).to have_link("Convert to virtual")
        click_link("Convert to virtual")

        expect(page).to have_current_path("/queue/appeals/#{appeal.external_id}" \
          "/tasks/#{appeal.tasks.last.id}/#{Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.value}")
      end
      step "cancel the step that starts the schedule workflow to test the next step" do
        click_button("Cancel")
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
        expect(page).not_to have_link("Convert to virtual")
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
        expect(page).to have_link("Convert to virtual")
        click_link("Convert to virtual")
        expect(page).to have_current_path("/hearings/#{appeal.external_id}/details")
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

        expect(page).not_to have_link("Convert to virtual")
        expect(page).to have_content("Hearing within next 10 days; contact Hearing Coordinator to convert to Virtual.")
      end
    end
  end
end
