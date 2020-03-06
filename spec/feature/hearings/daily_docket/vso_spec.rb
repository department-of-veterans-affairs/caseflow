# frozen_string_literal: true

RSpec.feature "Hearing Schedule Daily Docket for VSO", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["VSO"]) }
  let!(:hearing) { create(:hearing, :with_tasks) }
  let!(:vso) { create(:vso) }
  let!(:track_veteran_task) { create(:track_veteran_task, appeal: hearing.appeal, assigned_to: vso) }

  scenario "User has no assigned hearings" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    expect(page).to have_content(COPY::HEARING_SCHEDULE_DOCKET_NO_VETERANS)
    expect(page).to_not have_content("Edit Hearing Day")
    expect(page).to_not have_content("Lock Hearing Day")
    expect(page).to_not have_content("Hearing Details")
  end
end
