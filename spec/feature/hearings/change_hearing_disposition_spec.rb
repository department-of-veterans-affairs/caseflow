# frozen_string_literal: true

RSpec.shared_examples "Change hearing disposition" do
  let(:current_full_name) { "Leonela Harbold" }
  let(:hearing_admin_user) { create(:user, full_name: current_full_name, station_id: 101) }
  let(:veteran_link_text) { "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})" }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:hearing_task) { create(:hearing_task, parent: root_task) }
  let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
  let!(:change_task) { create(:change_hearing_disposition_task, parent: hearing_task) }
  let(:instructions_text) { "This is why I'm changing this hearing's disposition." }

  before do
    HearingAdmin.singleton.add_user(hearing_admin_user)
    User.authenticate!(user: hearing_admin_user)
  end

  context "there are hearing prep, transcription, and mail team members" do
    let(:mail_user) { create(:user, full_name: "Chinelo Mbanefo") }
    let(:transcription_user) { create(:user, full_name: "Li Hua Meng") }
    let(:hearing_user) { create(:user, full_name: "Lendvai Huot", roles: ["Hearing Prep"]) }
    let(:hearing_day) { create(:hearing_day, judge: hearing_user, scheduled_for: 1.month.from_now) }

    before do
      MailTeam.singleton.add_user(mail_user)
      TranscriptionTeam.singleton.add_user(transcription_user)
    end

    scenario "change hearing disposition to held" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
      end

      step "change the hearing disposition to held" do
        click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
        click_dropdown(
          {
            prompt: "Select",
            text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held
          },
          find(".cf-modal-body")
        )
        fill_in "Notes", with: instructions_text
        click_button("Submit")
        expect(page).to have_content(
          "Successfully changed hearing disposition to #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held}"
        )
      end

      step "return to the hearing admin organization queue and verify that the task is no longer there" do
        click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
        expect(page).to have_content("Unassigned (0)")
      end

      if appeal.is_a? Appeal
        step "visit and verify that the evidence submission window task is in the mail team queue" do
          User.authenticate!(user: mail_user)
          visit "/organizations/#{MailTeam.singleton.url}"
          expect(page).to have_content("Unassigned (1)")
          expect(page).to have_content "Evidence Submission Window Task"
          click_on veteran_link_text
          expect(page).to have_content ChangeHearingDispositionTask.last.label
        end

        step "visit and verify that the transcription task is in the transcription team queue" do
          User.authenticate!(user: transcription_user)
          visit "/organizations/#{TranscriptionTeam.singleton.url}"
          expect(page).to have_content("Unassigned (1)")
          expect(page).to have_content "Transcription Task"
          click_on veteran_link_text
          expect(page).to have_content ChangeHearingDispositionTask.last.label
        end

        step "visit and verify that the new hearing disposition is in the hearing schedule daily docket" do
          User.authenticate!(user: hearing_user)
          visit "/hearings/schedule/docket/" + hearing.hearing_day.id.to_s
          expect(dropdown_selected_value(find(".dropdown-#{hearing.uuid}-disposition"))).to eq(
            Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held
          )
        end

        step "visit and verify that the new hearing disposition is on the hearing details page" do
          visit "hearings/" + hearing.external_id.to_s + "/details"
          disposition_div = find("p", text: "DISPOSITION").first(:xpath, "ancestor::div")
          expect(disposition_div).to have_css("div", text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held)
        end

      elsif appeal.is_a? LegacyAppeal
        step "verify that the hearing disposition is now held" do
          click_on "Completed"
          click_on veteran_link_text
          expect(page).to have_content("Disposition: #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.held}")
        end
      end
    end
  end

  context "change hearing disposition to cancelled" do
    scenario "with hearing task association" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
      end

      step "change the hearing disposition to cancelled" do
        click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
        click_dropdown(
          {
            prompt: "Select",
            text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.cancelled
          },
          find(".cf-modal-body")
        )
        fill_in "Notes", with: instructions_text
        click_button("Submit")
        expect(page).to have_content(
          "Successfully changed hearing disposition to #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.cancelled}"
        )
      end

      step "return to the hearing admin organization queue and verify that the task is no longer there" do
        click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
        expect(page).to have_content("Unassigned (0)")
      end
    end
  end

  context "hearing task is missing association to hearing" do
    before do
      association.destroy
      hearing_task.reload
    end

    scenario "when changing hearing disposition" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on veteran_link_text
      end

      step "change the hearing disposition to cancelled" do
        expect(Raven).to receive(:capture_exception)
          .with(AssignHearingDispositionTask::HearingAssociationMissing, any_args) do
            @raven_called = true
          end

        click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
        click_dropdown(
          {
            prompt: "Select",
            text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.cancelled
          },
          find(".cf-modal-body")
        )
        fill_in "Notes", with: instructions_text
        click_button("Submit")

        expect(page).to have_content(format(COPY::HEARING_TASK_ASSOCIATION_MISSING_MESASAGE, hearing_task.id))
      end
    end
  end

  context "there's a hearings management user" do
    let!(:hearing_mgmt_user) do
      create(:user, full_name: "Janaan Handal", station_id: 101, roles: ["Build HearSched"])
    end
    let!(:hearing_day) do
      create(
        :hearing_day,
        regional_office: regional_office_code,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 30.days
      )
    end
    let!(:staff) { create(:staff, stafkey: regional_office_code, stc2: 2, stc3: 3, stc4: 4) }
    let(:veteran_hearing_link_text) { "#{appeal.veteran_full_name} | #{appeal.veteran_file_number}" }

    before do
      HearingsManagement.singleton.add_user(hearing_mgmt_user)
    end

    context "changing hearing disposition" do
      before do
        cache_appeals
      end

      scenario "change hearing disposition to postponed" do
        step "visit the hearing admin organization queue and click on the veteran's name" do
          visit "/organizations/#{HearingAdmin.singleton.url}"
          expect(page).to have_content("Unassigned (1)")
          click_on veteran_link_text
        end

        step "change the hearing disposition to postponed" do
          click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
          click_dropdown(
            {
              prompt: "Select",
              text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.postponed
            },
            find(".cf-modal-body")
          )
          fill_in "Notes", with: instructions_text
          click_button("Submit")
          expect(page).to have_content(
            "Successfully changed hearing disposition to #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.postponed}"
          )
        end

        step "return to the hearing admin organization queue and verify that the task is no longer there" do
          click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
          expect(page).to have_content("Unassigned (0)")
        end

        step "visit hearings schedule and verify that the schedule hearing task is there" do
          User.authenticate!(user: hearing_mgmt_user)
          visit "hearings/schedule/assign"
          expect(page).to have_content("Regional Office")
          click_dropdown(text: "Denver")
          click_button(waiting_button_text, exact: true)
          click_on veteran_hearing_link_text
          expect(page).to have_content(ScheduleHearingTask.last.label)
        end

        step "verify that instructions and actions are available on the schedule hearing task" do
          schedule_row = find("dd", text: ScheduleHearingTask.last.label).find(:xpath, "ancestor::tr")
          schedule_row.find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          expect(schedule_row).to have_content(instructions_text)
          expect(schedule_row).to have_css(
            ".cf-select__control .cf-select__placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
          )
        end
      end

      scenario "change hearing disposition to no_show" do
        step "visit the hearings management organization queue and click on the veteran's name" do
          visit "/organizations/#{HearingAdmin.singleton.url}"
          expect(page).to have_content("Unassigned (1)")
          click_on veteran_link_text
        end

        step "change the hearing disposition to no show" do
          click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
          click_dropdown(
            {
              prompt: "Select",
              text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.no_show
            },
            find(".cf-modal-body")
          )
          fill_in "Notes", with: instructions_text
          click_button("Submit")
          expect(page).to have_content(
            "Successfully changed hearing disposition to #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.no_show}"
          )
        end

        step "return to the hearing admin organization queue and verify that the task is no longer unassigned" do
          click_queue_switcher COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL % HearingAdmin.singleton.name
          expect(page).to have_content("Unassigned (0)")
        end

        step "verify that there's a NoShowHearingTask with a hold in the HearingsManagement org assigned queue" do
          User.authenticate!(user: hearing_mgmt_user)
          visit "/organizations/#{HearingsManagement.singleton.url}"
          click_on "Assigned (1)"
          find("td", text: "No Show Hearing Task").find(:xpath, "ancestor::tr").click_on veteran_link_text
          no_show_active_row = find("dd", text: "No Show Hearing Task").find(:xpath, "ancestor::tr")
          expect(no_show_active_row).to have_content(
            "DAYS ON HOLD 0 of #{NoShowHearingTask::DAYS_ON_HOLD}", normalize_ws: true
          )
        end
      end

      scenario "change hearing disposition to scheduled_in_error" do
        step "visit the hearing admin organization queue and click on the veteran's name" do
          visit "/organizations/#{HearingAdmin.singleton.url}"
          expect(page).to have_content("Unassigned (1)")
          click_on veteran_link_text
        end

        step "change the hearing disposition to scheduled_in_error" do
          click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
          click_dropdown(
            {
              prompt: "Select",
              text: Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.scheduled_in_error
            },
            find(".cf-modal-body")
          )
          fill_in "Notes", with: instructions_text
          click_button("Submit")
          expect(page).to have_content(
            "Successfully changed hearing disposition to " \
              "#{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.scheduled_in_error}"
          )
        end
      end
    end

    context "a hearing has mistakenly been marked postponed" do
      let(:hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
      let(:case_hearing_disposition) { :disposition_postponed }
      let!(:cancel_change_task) { change_task.update!(status: Constants.TASK_STATUSES.cancelled) }
      let!(:hearing_task_2) { create(:hearing_task, parent: root_task) }
      let!(:association_2) do
        create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
      end
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: hearing_task_2) }
      let(:instructions_text) { "This hearing is postponed, but it should be held." }

      before do
        User.authenticate!(user: hearing_mgmt_user)
        cache_appeals
      end

      scenario "correct the hearing disposition to held" do
        step "visit hearings schedule and verify that the schedule hearing task is there" do
          visit "hearings/schedule/assign"
          expect(page).to have_content("Regional Office")
          click_dropdown(text: "Denver")
          click_button(waiting_button_text, exact: true)
          click_on veteran_hearing_link_text
          expect(page).to have_content(ScheduleHearingTask.last.label)
        end

        step "choose the change previous hearing disposition action and fill out the form" do
          schedule_hearing_row = find("dd", text: ScheduleHearingTask.last.label).find(:xpath, "ancestor::tr")
          click_dropdown(
            { text: Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.label },
            schedule_hearing_row
          )
          expect(page).to have_content(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_TITLE)
          fill_in "Notes", with: instructions_text
          click_button "Submit"
          expect(page).to have_content(
            format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
          )
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

  context "there are other hearing admin and hearings management members" do
    let(:other_admin_full_name) { "Remika Hanisco" }
    let!(:other_admin_user) { create(:user, full_name: other_admin_full_name, station_id: 101) }
    let(:admin_full_names) { ["Bisar Helget", "Rose Hidrogo", "Rihab Hancin", "Abby Hudmon"] }
    let(:mgmt_full_names) { ["Claudia Heraty", "Nouf Heigl", "Hayley Houlahan", "Bahiya Haese"] }
    let(:assign_instructions_text) { "This is why I'm assigning this to you." }

    before do
      HearingAdmin.singleton.add_user(other_admin_user)

      admin_full_names.each do |name|
        user = create(:user, full_name: name, station_id: 101)
        HearingAdmin.singleton.add_user(user)
      end

      mgmt_full_names.each do |name|
        user = create(:user, full_name: name, station_id: 101)
        HearingsManagement.singleton.add_user(user)
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
        choices = click_dropdown({ text: other_admin_full_name }, find(".cf-modal-body"))

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
        find(
          "#currently-active-tasks button",
          text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL,
          id: ChangeHearingDispositionTask.last.id.to_s
        ).click
        expect(page).to have_content(assign_instructions_text)
      end
    end

    scenario "assign change hearing disposition task to self" do
      step "visit the hearing admin organization queue and click on the veteran's name" do
        visit "/organizations/#{HearingAdmin.singleton.url}"
        expect(page).to have_content("Unassigned (1)")
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      end

      step "assign the task to self" do
        click_dropdown(prompt: "Select an action", text: "Assign to person")

        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: assign_instructions_text
        click_on "Submit"
        expect(page).to have_content COPY::REASSIGN_TASK_SUCCESS_MESSAGE % current_full_name
      end

      step "the task in my personal queue" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_content(ChangeHearingDispositionTask.last.label)
        find(
          "#currently-active-tasks button",
          text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL,
          id: ChangeHearingDispositionTask.last.id.to_s
        ).click
        expect(page).to have_content(assign_instructions_text)
      end
    end
  end

  describe "create change hearing disposition task action is available to hearing admin user" do
    let(:instructions_text) { "my instructions." }

    before do
      change_task.destroy!
    end

    context "disposition task" do
      let!(:task) { create(:assign_hearing_disposition_task, parent: hearing_task) }

      scenario "can create a change hearing disposition task" do
        visit(appeal_path)
        expect(page).to have_content(AssignHearingDispositionTask.last.label)
        click_dropdown(text: Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.label)
        expect(page).to have_content(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_TITLE)
        fill_in "Notes", with: instructions_text
        click_button "Submit"
        expect(page).to have_content(
          format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
        )
      end

      context "transcription task" do
        let!(:child_task) { create(:transcription_task, parent: task) }

        scenario "can create a change hearing disposition task" do
          visit(appeal_path)
          expect(page).to have_content(TranscriptionTask.last.label)
          click_dropdown(text: Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.label)
          fill_in "Notes", with: instructions_text
          click_button "Submit"
          expect(page).to have_content(
            format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
          )
        end
      end

      context "no show hearing task" do
        let!(:child_task) { create(:no_show_hearing_task, parent: task) }

        scenario "can create a change hearing disposition task" do
          visit(appeal_path)
          expect(page).to have_content(NoShowHearingTask.last.label)
          click_dropdown(text: Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.label)
          fill_in "Notes", with: instructions_text
          click_button "Submit"
          expect(page).to have_content(
            format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
          )
        end
      end
    end

    context "schedule hearing task" do
      let!(:task) { create(:schedule_hearing_task, parent: hearing_task) }

      scenario "cannot create a change hearing disposition task" do
        visit(appeal_path)
        expect(page).to have_content(ScheduleHearingTask.last.label)
        expect(page).to_not have_css(".cf-select__control")
      end

      context "hearing admin task" do
        let!(:child_task) do
          create(:hearing_admin_action_incarcerated_veteran_task, parent: task)
        end

        scenario "cannot create a change hearing disposition task" do
          visit(appeal_path)
          expect(page).to have_content(HearingAdminActionIncarceratedVeteranTask.last.label)
          expect(page).to_not have_css(".cf-select__control")
        end
      end
    end
  end
end

RSpec.feature "Change ama and legacy hearing disposition", :all_dbs do
  let(:veteran) { create(:veteran, first_name: "Chibueze", last_name: "Vanscoy", file_number: 800_888_001) }
  let(:regional_office_code) { "RO39" } # Denver
  let(:hearing_day) { create(:hearing_day) }
  let(:hearing_disposition) { nil }

  describe "with AMA appeal" do
    let(:appeal) do
      create(
        :appeal,
        :hearing_docket,
        closest_regional_office: regional_office_code,
        veteran_file_number: veteran.file_number
      )
    end
    let(:hearing) do
      create(:hearing, appeal: appeal, hearing_day: hearing_day, disposition: hearing_disposition)
    end
    let(:waiting_button_text) { "AMA Veterans Waiting" }
    let(:appeal_path) { "/queue/appeals/#{appeal.uuid}" }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

    include_examples "Change hearing disposition"
  end

  describe "with Legacy appeal" do
    let(:case_hearing_disposition) { :disposition_nil }
    let(:vacols_case) { create(:case, :status_active, :aod, bfcorlid: "#{veteran.file_number}S") }
    let(:appeal) do
      create(
        :legacy_appeal,
        closest_regional_office: regional_office_code,
        vacols_case: vacols_case
      )
    end
    let(:case_hearing) do
      create(:case_hearing, case_hearing_disposition, vdkey: hearing_day.id, folder_nr: appeal.vacols_id)
    end
    let(:hearing) do
      create(:legacy_hearing, appeal: appeal, case_hearing: case_hearing)
    end
    let(:waiting_button_text) { "Legacy Veterans Waiting" }
    let(:appeal_path) { "/queue/appeals/#{appeal.vacols_id}" }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

    include_examples "Change hearing disposition"
  end
end
