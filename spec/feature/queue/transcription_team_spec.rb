# frozen_string_literal: true

RSpec.feature "TranscriptionTeam", :postgres do
  let(:transcription_team_member) { create(:user) }
  let(:veteran) { create(:veteran, first_name: "Maisie", last_name: "Varesko", file_number: 201_905_061) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
  let(:veteran_link_text) { "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})" }
  let!(:root_task) { create(:root_task, appeal: appeal) }
  let!(:hearing_task) { create(:hearing_task, parent: root_task) }
  let!(:disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task) }
  let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

  before do
    TranscriptionTeam.singleton.add_user(transcription_team_member)
    User.authenticate!(user: transcription_team_member)
  end

  describe "transcription team member completes a transcription task" do
    it "does not have an input field for instructions" do
      visit("/organizations/transcription")
      click_on veteran_link_text
      click_dropdown(text: Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h[:label])

      expect(page).to_not have_field("instructions")
    end

    scenario "completes the task" do
      visit("/organizations/transcription")
      click_on veteran_link_text
      click_dropdown(text: Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h[:label])
      click_on "Mark complete"

      expect(page).to have_content("#{appeal.veteran_full_name}'s case has been marked complete")
      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
    end

    scenario "cancels the task and sends appeal to hearings management" do
      visit("/organizations/transcription")
      click_on veteran_link_text
      click_dropdown(text: Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h[:label])
      fill_in "taskInstructions", with: "Cancelling task"
      click_on "Submit"

      expect(page).to have_content(
        format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_TITLE, appeal.veteran_full_name)
      )

      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(root_task.children.where(type: HearingTask.name).count).to eq(2)
      open_hearing_task = root_task.children.find_by(type: HearingTask.name, status: Constants.TASK_STATUSES.on_hold)
      expect(open_hearing_task.children.first.type).to eq(ScheduleHearingTask.name)
      expect(open_hearing_task.children.first.assigned_to).to eq(Bva.singleton)
    end

    context "with a hearing and a hearing admin member" do
      let(:hearing_day) { create(:hearing_day) }
      let(:hearing) { create(:hearing, appeal: appeal, hearing_day: hearing_day) }
      let!(:association) do
        create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task)
      end
      let(:admin_full_name) { "Steinlaug Huppert" }
      let(:hearing_admin_user) { create(:user, full_name: admin_full_name, station_id: 101) }
      let(:instructions_text) { "This is why I want a hearing disposition change!" }

      before do
        HearingAdmin.singleton.add_user(hearing_admin_user)
      end

      scenario "transcription team member requests a hearing disposition change" do
        step "visit the transcription team organization queue and submit a request for hearing disposition change" do
          visit("/organizations/transcription")
          click_on veteran_link_text
          expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
          click_dropdown(text: Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.label)
          fill_in "Notes", with: instructions_text
          click_button "Submit"
          expect(page).to have_content(
            format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
          )
          expect(page).to_not have_content veteran_link_text
        end

        step "log in as a hearing administrator and verify that the task is in the org queue" do
          User.authenticate!(user: hearing_admin_user)
          visit "/organizations/#{HearingAdmin.singleton.url}"
          click_on veteran_link_text
          expect(page).to have_content(ChangeHearingDispositionTask.last.label)
        end

        step "verify task instructions and submit a new disposition" do
          schedule_row = find("dd", text: ChangeHearingDispositionTask.last.label).find(:xpath, "ancestor::tr")
          schedule_row.find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          expect(schedule_row).to have_content(instructions_text)
          click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
          click_dropdown(
            {
              prompt: "Select",
              text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held
            },
            find(".cf-modal-body")
          )
          fill_in "Notes", with: "I'm changing this to held."
          click_button("Submit")
          expect(page).to have_content(
            "Successfully changed hearing disposition to #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held}"
          )
        end
      end
    end
  end
end
