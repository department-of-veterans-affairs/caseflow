# frozen_string_literal: true

RSpec.feature "Convert scheduled hearing type" do
  let!(:appeal) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
    a
  end

  let!(:appeal_deadline) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
    a
  end

  let!(:hearing_day) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 12.days) }
  let(:hearing_day_deadline) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days) }

  context "for Hearing coordinator user" do
    let!(:current_user) { User.authenticate!(roles: ["Edit HearSched"]) }
    before do
      HearingsManagement.singleton.add_user(current_user)
    end
    scenario "Schedule veteran" do
      step "select from dropdown" do
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)

      end
    end
  end

  before do
    vso.add_user(vso_user)
    User.authenticate!(user: vso_user)
  end
  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
  let!(:vso_user) { create(:user, :vso_role) }

  context "for VSO users" do
    scenario "Convert scheduled hearing to Virtual" do
      step "navigate to the hearings form" do
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Video")
        expect(page).to have_link("Convert to virtual")
        click_link("Convert to virtual")
        expect(page).to have_current_path("/hearings/#{appeal.external_id}/details")
      end
      step "cancel the step that starts the schedule workflow to test the next step" do
        click_button("Cancel")
      end
    end

    scenario "Hearing will be held within 11 days" do
      visit "queue/appeals/#{appeal_deadline.uuid}"
      step "info alert will show instead of link" do
        expect(page).not_to have_link("Convert to virtual")
        expect(page).to have_content("Hearing within next 10 days; contact Hearing Coordinator to convert to Virtual.")
      end
    end
  end
end
