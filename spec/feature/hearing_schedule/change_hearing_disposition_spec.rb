# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Change hearing disposition spec" do
  let(:current_user) { FactoryBot.create(:user, css_id: "BVATWARNER", station_id: 101) }
  let(:hearing_day) { FactoryBot.create(:hearing_day) }
  let(:veteran) { FactoryBot.create(:veteran, first_name: "Chibueze", last_name: "Vanscoy", file_number: 800_888_001) }
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket, veteran_file_number: veteran.file_number) }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
  let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
  let(:hearing) { FactoryBot.create(:hearing, appeal: appeal, hearing_day: hearing_day) }
  let!(:association) { FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
  let!(:change_task) { FactoryBot.create(:change_hearing_disposition_task, parent: hearing_task, appeal: appeal) }

  before do
    OrganizationsUser.add_user_to_organization(current_user, HearingAdmin.singleton)
    User.authenticate!(user: current_user)
  end

  scenario "change to postponed" do
    visit "/organizations/#{HearingAdmin.singleton.url}"
    click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
    click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
    click_dropdown(prompt: "Select", text: "Postponed", container: ".cf-modal-body")
    fill_in "Notes", with: "These are my detailed postponed hearing notes."
    click_button("Submit")
    expect(page).to have_content("Successfully changed hearing disposition to Postponed")
    visit "/organizations/#{HearingAdmin.singleton.url}"
    expect(page).to have_content("Unassigned (0)")
  end
end
