# frozen_string_literal: true

RSpec.feature "Colocated checkout flows", :all_dbs do
  let(:attorney_user) { create(:default_user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }
  let(:colocated_user) { create(:user) }
  let!(:vacols_colocated) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }
  let(:veteran1_first_name) { "Natasha" }
  let(:veteran1_last_name) { "Vanbruggen" }
  let!(:veteran1) do
    create(
      :veteran,
      first_name: veteran1_first_name,
      last_name: veteran1_last_name,
      file_number: 524_481_638
    )
  end

  let(:veteran2_first_name) { "Safa" }
  let(:veteran2_last_name) { "Vidal" }
  let!(:veteran2) do
    create(
      :veteran,
      first_name: veteran2_first_name,
      last_name: veteran2_last_name,
      file_number: 267_990_255
    )
  end

  context "given a valid legacy appeal" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          :assigned,
          correspondent: create(:correspondent, snamef: veteran1_first_name, snamel: veteran1_last_name),
          bfcorlid: veteran1.file_number,
          user: colocated_user,
          case_issues: create_list(:case_issue, 1)
        )
      )
    end
    let!(:appeal_with_translation_task) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          :assigned,
          correspondent: create(:correspondent, snamef: veteran2_first_name, snamel: veteran2_last_name),
          bfcorlid: veteran2.file_number,
          user: colocated_user,
          case_issues: create_list(:case_issue, 1)
        )
      )
    end
    let!(:colocated_action) do
      create(
        :colocated_task,
        :pending_scanning_vbms,
        appeal: appeal,
        assigned_at: nil,
        assigned_to: colocated_user,
        assigned_by: attorney_user
      )
    end
    let!(:translation_action) do
      create(
        :colocated_task,
        :translation,
        appeal: appeal_with_translation_task,
        assigned_to: colocated_user,
        assigned_by: attorney_user
      )
    end

    before do
      User.authenticate!(user: colocated_user)
    end

    scenario "returns task to assigning attorney" do
      visit "/queue"

      appeal = colocated_action.appeal

      vet_name = appeal.veteran_full_name

      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"
      click_dropdown(text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h[:label])

      expect(page).to have_content(COPY::MARK_TASK_COMPLETE_BUTTON)
      click_on COPY::MARK_TASK_COMPLETE_BUTTON

      expect(page).to have_content(
        format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, vet_name)
      )

      expect(colocated_action.reload.status).to eq(Constants.TASK_STATUSES.completed)
      expect(colocated_action.assigned_at.to_date).to eq Time.zone.today
    end

    scenario "places task on hold" do
      visit "/queue"

      appeal = colocated_action.appeal

      vet_name = appeal.veteran_full_name
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"

      expect(page).to have_content("Actions")

      click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h[:label])

      expect(page).to have_content(Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

      click_dropdown({ index: 6 }, find(".cf-modal-body"))
      expect(page).to have_content(COPY::COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY)

      hold_duration = [rand(100), 1].max
      fill_in COPY::COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY, with: hold_duration

      instructions = generate_words 5
      fill_in "instructions", with: instructions
      click_on(COPY::MODAL_SUBMIT_BUTTON)

      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, vet_name, hold_duration)
      )
      expect(colocated_action.reload.calculated_on_hold_duration).to eq hold_duration
      expect(colocated_action.status).to eq "on_hold"
      expect(colocated_action.instructions[1]).to eq instructions
    end

    scenario "sends task to team" do
      visit "/queue"

      appeal = translation_action.appeal
      vacols_case = appeal.case_record

      # team_name = Constants::CO_LOCATED_ADMIN_ACTIONS[translation_action.action]
      # team_name = Constants::CO_LOCATED_ADMIN_ACTIONS.values.last
      vet_name = appeal.veteran_full_name
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"

      # current flake: https://circleci.com/gh/department-of-veterans-affairs/caseflow/53427
      click_dropdown(index: 0, text: "Assign to team")
      expect(page).to have_content("Assign task")

      click_dropdown({ index: 1 }, find(".cf-modal-body"))
      fill_in "taskInstructions", with: "testing this out"
      click_on COPY::MODAL_SUBMIT_BUTTON

      # click_on COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(
        format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, "Litigation Support")
      )

      expect(translation_action.reload.status).to eq "on_hold"
      # expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[translation_action.action.to_sym]
    end
  end
end
