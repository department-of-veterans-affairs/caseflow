# frozen_string_literal: true

RSpec.feature "Case Assignment flows", :all_dbs do
  let(:attorney_user) { create(:user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }

  context "given a valid legacy appeal and an attorney user" do
    let!(:appeals) do
      Array.new(3) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            case_issues: create_list(:case_issue, 1)
          )
        )
      end
    end

    before do
      u = create(:user)
      Colocated.singleton.add_user(u)

      User.authenticate!(user: attorney_user)
    end

    scenario "adds colocated tasks" do
      # step "navigates to the 'submit admin action' page"
      visit "/queue"
      click_on "#{appeals[0].veteran_full_name} (#{appeals[0].sanitized_vbms_id})"
      click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label])

      expect(page).to have_content(COPY::ADD_COLOCATED_TASK_SUBHEAD)

      # step "fills in and submits the form for two identical admin actions"
      action = ColocatedTask.actions_assigned_to_colocated.sample
      selected_opt_0 = Constants::CO_LOCATED_ADMIN_ACTIONS[action]
      instructions = generate_words(5)

      click_dropdown(text: selected_opt_0) do
        visible_options = page.find_all(".cf-select__option")
        expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
      end

      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions

      click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL

      expect(all('div[id^="action_"]').count).to eq 2

      within all('div[id^="action_"]')[1] do
        click_dropdown(text: selected_opt_0)
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions
      end

      click_on COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL

      expect(page).to have_content(
        format(COPY::ADD_COLOCATED_TASK_ACTION_DUPLICATE_ERROR, selected_opt_0.upcase, instructions)
      )

      # step "removes the duplicate and submits the form for a new admin action"

      within all('div[id^="action_"]')[1] do
        click_on COPY::ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL
      end

      click_on COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL

      expect(page).to have_content("You have assigned an administrative action (#{selected_opt_0})")
      expect(page.current_path).to eq "/queue"

      expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, 2))
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

      # step "navigates to the 'submit admin action' page for a different veteran"
      click_on "#{appeals[1].veteran_full_name} (#{appeals[1].sanitized_vbms_id})"
      click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label])

      expect(page).to have_content(COPY::ADD_COLOCATED_TASK_SUBHEAD)

      # step "fills in the form for a new admin action"
      action = ColocatedTask.actions_assigned_to_colocated.sample
      selected_opt_1 = Constants::CO_LOCATED_ADMIN_ACTIONS[action]

      click_dropdown(text: selected_opt_1)
      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: generate_words(4)

      # step "adds another admin action"
      click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL

      expect(all('div[id^="action_"]').count).to eq 2

      action = ColocatedTask.actions_assigned_to_colocated.sample
      selected_opt_2 = Constants::CO_LOCATED_ADMIN_ACTIONS[action]

      within all('div[id^="action_"]')[1] do
        click_dropdown(text: selected_opt_2)
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: generate_words(5)
      end

      # step "adds a third admin action with no instructions"
      within all('div[id^="action_"]')[1] do
        click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL
      end

      expect(all('div[id^="action_"]').count).to eq 3

      action = ColocatedTask.actions_assigned_to_colocated.sample
      selected_opt_3 = Constants::CO_LOCATED_ADMIN_ACTIONS[action]

      within all('div[id^="action_"]')[2] do
        click_dropdown(text: selected_opt_3)
      end

      # step "removes the second admin action"
      within all('div[id^="action_"]')[1] do
        click_on COPY::ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL
      end

      expect(all('div[id^="action_"]').count).to eq 2

      # step "tries to submit incomplete actions, corrects error"
      click_on COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL

      expect(page).to have_content COPY::INSTRUCTIONS_ERROR_FIELD_REQUIRED

      within all('div[id^="action_"]')[1] do
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: generate_words(4)
      end

      # step "submits two admin actions"
      click_on COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL

      expect(page).to have_content("You have assigned 2 administrative actions (#{selected_opt_1}, #{selected_opt_3})")
      expect(page.current_path).to eq "/queue"

      expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, 1))
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 2))
    end
  end
end
