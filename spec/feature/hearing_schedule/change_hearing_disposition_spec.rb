# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Change hearing disposition" do
  let(:current_full_name) { "Leonela Harbold" }
  let(:hearing_admin_user) { FactoryBot.create(:user, full_name: current_full_name, station_id: 101) }
  let(:hearing_day) { FactoryBot.create(:hearing_day) }
  let(:veteran) { FactoryBot.create(:veteran, first_name: "Chibueze", last_name: "Vanscoy", file_number: 800_888_001) }
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket, veteran_file_number: veteran.file_number) }
  let(:veteran_link_text) { "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})" }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
  let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
  let(:hearing) { FactoryBot.create(:hearing, appeal: appeal, hearing_day: hearing_day) }
  let!(:association) { FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
  let!(:change_task) { FactoryBot.create(:change_hearing_disposition_task, parent: hearing_task, appeal: appeal) }
  let(:instructions_text) { "This is why I'm changing this hearing's disposition." }

  before do
    OrganizationsUser.add_user_to_organization(hearing_admin_user, HearingAdmin.singleton)
    User.authenticate!(user: hearing_admin_user)
  end

  context "there are transcription and mail team members" do
    let(:mail_user) { FactoryBot.create(:user, full_name: "Chinelo Mbanefo") }
    let(:transcription_user) { FactoryBot.create(:user, full_name: "Li Hua Meng") }

    before do
      OrganizationsUser.add_user_to_organization(mail_user, MailTeam.singleton)
      OrganizationsUser.add_user_to_organization(transcription_user, TranscriptionTeam.singleton)
    end

    scenario "change hearing disposition to held" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
      end

      step "change the hearing disposition to held" do
        click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
        click_dropdown(prompt: "Select", text: "Held", container: ".cf-modal-body")
        fill_in "Notes", with: instructions_text
        click_button("Submit")
        expect(page).to have_content("Successfully changed hearing disposition to Held")
      end

      step "return to the hearing admin organization queue and verify that the task is no longer there" do
        click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
        expect(page).to have_content("Unassigned (0)")
      end

      step "visit and verify that the evidence submission window task is in the mail team queue" do
        User.authenticate!(user: mail_user)
        visit "/organizations/#{MailTeam.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        expect(page).to have_content veteran_link_text
        expect(page).to have_content "Evidence Submission Window Task"
      end

      step "visit and verify that the transcription task is in the transcription team queue" do
        User.authenticate!(user: transcription_user)
        visit "/organizations/#{TranscriptionTeam.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        expect(page).to have_content veteran_link_text
        expect(page).to have_content "Transcription Task"
      end
    end
  end

  scenario "change hearing disposition to cancelled" do
    step "visit the hearing admin organization queue and click on the veteran's name" do
      visit "/organizations/#{HearingAdmin.singleton.url}"
      expect(page).to have_content("Unassigned (1)")
      click_on veteran_link_text
    end

    step "change the hearing disposition to cancelled" do
      click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
      click_dropdown(prompt: "Select", text: "Cancelled", container: ".cf-modal-body")
      fill_in "Notes", with: instructions_text
      click_button("Submit")
      expect(page).to have_content("Successfully changed hearing disposition to Cancelled")
    end

    step "return to the hearing admin organization queue and verify that the task is no longer there" do
      click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
      expect(page).to have_content("Unassigned (0)")
    end
  end

  context "there's a hearings management user" do
    let(:hearing_mgmt_user) { FactoryBot.create(:user, full_name: "Janaan Handal", station_id: 101) }

    before do
      OrganizationsUser.add_user_to_organization(hearing_mgmt_user, HearingsManagement.singleton)
    end

    scenario "change hearing disposition to postponed" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
      end

      step "change the hearing disposition to postponed" do
        click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
        click_dropdown(prompt: "Select", text: "Postponed", container: ".cf-modal-body")
        fill_in "Notes", with: instructions_text
        click_button("Submit")
        expect(page).to have_content("Successfully changed hearing disposition to Postponed")
      end

      step "return to the hearing admin organization queue and verify that the task is no longer there" do
        click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
        expect(page).to have_content("Unassigned (0)")
      end

      step "visit the hearings management organization queue and verify that the schedule hearing task is there" do
        User.authenticate!(user: hearing_mgmt_user)
        visit "/organizations/#{HearingsManagement.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
        expect(page).to have_content(ScheduleHearingTask.last.label)
      end

      step "verify that the instructions are visible on the schedule hearing task" do
        find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(instructions_text)
      end
    end
  end

  scenario "change hearing disposition to no_show" do
    step "visit the hearing admin organization queue and click on the veteran's name" do
      visit "/organizations/#{HearingAdmin.singleton.url}"
      expect(page).to have_content("Unassigned (1)")
      click_on veteran_link_text
    end

    step "change the hearing disposition to no show" do
      click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
      click_dropdown(prompt: "Select", text: "No Show", container: ".cf-modal-body")
      fill_in "Notes", with: instructions_text
      click_button("Submit")
      expect(page).to have_content("Successfully changed hearing disposition to No Show")
    end

    step "return to the hearing admin organization queue and verify that the task is no longer unassigned" do
      click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
      expect(page).to have_content("Unassigned (0)")
    end

    step "verify that there's a NoShowHearingTask with a hold in the assigned queue" do
      click_on "Assigned (2)"
      find("td", text: "No Show Hearing Task").find(:xpath, "ancestor::tr").click_on veteran_link_text
      no_show_active_row = find("dd", text: "NoShowHearingTask").find(:xpath, "ancestor::tr")
      expect(no_show_active_row).to have_content("DAYS ON HOLD 0 of 25", normalize_ws: true)
    end
  end

  context "there are other hearing admin and hearings management members" do
    let(:other_admin_full_name) { "Remika Hanisco" }
    let!(:other_admin_user) { FactoryBot.create(:user, full_name: other_admin_full_name, station_id: 101) }
    let(:admin_full_names) { ["Bisar Helget", "Rose Hidrogo", "Rihab Hancin", "Abby Hudmon"] }
    let(:mgmt_full_names) { ["Claudia Heraty", "Nouf Heigl", "Hayley Houlahan", "Bahiya Haese"] }
    let(:assign_instructions_text) { "This is why I'm assigning this to you." }

    before do
      OrganizationsUser.add_user_to_organization(other_admin_user, HearingAdmin.singleton)

      admin_full_names.each do |name|
        user = FactoryBot.create(:user, full_name: name, station_id: 101)
        OrganizationsUser.add_user_to_organization(user, HearingAdmin.singleton)
      end

      mgmt_full_names.each do |name|
        user = FactoryBot.create(:user, full_name: name, station_id: 101)
        OrganizationsUser.add_user_to_organization(user, HearingsManagement.singleton)
      end
    end

    scenario "assign change hearing disposition task to another user" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      end

      step "assign the task to the other user" do
        click_dropdown(prompt: "Select an action", text: "Assign to person")
        choices = click_dropdown(text: other_admin_full_name, container: ".cf-modal-body")

        # only hearing admin users can be assigned the task
        expect(choices).to include(*admin_full_names)
        expect(choices).to_not include(*mgmt_full_names)

        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: assign_instructions_text
        click_on "Submit"
        expect(page).to have_content COPY::REASSIGN_TASK_SUCCESS_MESSAGE % other_admin_full_name
      end

      step "the other user logs in and sees the task in their queue" do
        User.authenticate!(user: other_admin_user)
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_content(ChangeHearingDispositionTask.last.label)
        find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(assign_instructions_text)
      end
    end
  end
end
