# frozen_string_literal: true

RSpec.feature "Convert scheduled hearing type" do
  before { FeatureToggle.enable!(:schedule_veteran_virtual_hearing) }
  after { FeatureToggle.disable!(:schedule_veteran_virtual_hearing) }
  let!(:appeal) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
    a
  end

  context "for Hearing coordinator user" do
    before do
      current_user = User.authenticate!(roles: ["Edit HearSched", "Build HearSched"])
      HearingsManagement.singleton.add_user(current_user)
    end
    let!(:hearing_day) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days, regional_office: "RO63") }

    scenario "Schedule veteran" do
      step "select from dropdown" do
        visit "queue/appeals/#{appeal.uuid}"
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
      end

      step "fill in form" do
        fill_in "Notes", with: "asfsefdsfdf"
        click_dropdown(name: "regionalOffice", index: 1)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "optionalHearingTime0", index: 0)
        click_button(text: "Schedule")
      end
    end
  end

  context "for VSO users" do
    before do
      vso.add_user(vso_user)
      User.authenticate!(user: vso_user)
    end
    let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
    let!(:vso_user) { create(:user, :vso_role) }

    scenario "Hearing will be held within 11 days" do
      visit "queue/appeals/#{appeal_deadline.uuid}"
      step "info alert will show instead of link" do
        expect(page).not_to have_link("Convert to virtual")
        expect(page).to have_content("Hearing within next 10 days; contact Hearing Coordinator to convert to Virtual.")
      end
    end
  end
end
