# frozen_string_literal: true

feature "duplicate JudgeAssignTask investigation" do
  before do
    User.authenticate!(user: judge_user)
  end

  # Ticket: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/212#
  # Target state: there should be no more than 1 open JudgeAssignTask
  describe "Judge reassigns JudgeAssignTask in first tab and complete task in second tab" do
    let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Anna Juarez") }
    let!(:judge_staff) { create(:staff, :judge_role, user: judge_user) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge_user) }
    let(:attorney_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Steven Ahr") }
    let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }
    let(:attorney_user_second) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "John Lee") }
    let!(:attorney_staff_second) { create(:staff, :attorney_role, user: attorney_user_second) }

    let(:root_task) { create(:root_task) }
    let(:judge_assign_task) { create(:ama_judge_assign_task, parent: root_task, assigned_to: judge_user) }
    let(:appeal) { judge_assign_task.appeal }
    let(:uuid) { appeal.uuid }

    scenario "Caseflow creates multiple JudgeDecisionReview and JudgeAssign tasks" do
      # open a window and visit case details page, window A
      visit "/queue/appeals/#{appeal.uuid}"

      # open a second window and visit case details page, window B
      second_window = open_new_window
      within_window second_window do
        visit "/queue/appeals/#{appeal.uuid}"
      end

      # in window A, reassign the JudgeAssignTask to another judge
      first_judge_assign_task_id = appeal.tasks.select { |task| task.type == "JudgeAssignTask" }[0].id
      click_dropdown(prompt: "Select an action", text: "Re-assign to a judge")
      click_dropdown(prompt: "Select a user", text: judge_user.full_name)
      fill_in "taskInstructions", with: "reassign this task! teamwork makes the dreamwork!"
      click_on "Submit"

      expect(page).to have_content(COPY::REASSIGN_TASK_SUCCESS_MESSAGE, judge_user.full_name)
      expect(Task.find(first_judge_assign_task_id).status).to eq("cancelled")
      visit "/queue/appeals/#{appeal.uuid}"

      # in window B, complete the JudgeAssignTask
      within_window second_window do
        click_dropdown(prompt: "Select an action", text: "Assign to attorney")
        click_dropdown(prompt: "Select a user", text: "Other")
        click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
        fill_in "taskInstructions", with: "assign to attorney"
        click_on "Submit"

        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, attorney_user.full_name)

        visit "/queue/appeals/#{appeal.uuid}"
        # Complete JudgeAssignTask to create an invalid number of AttorneyTasks
        # TODO - figure out how to select an option from the second dropdown
        # below correctly selects the second task action dropdown
        find("#currently-active-tasks > div:nth-child(4) > table > tbody > tr:nth-child(3) > td.taskContainerStyling.taskActionsContainerStyling > div > div > div > div > div > div").click
        # below - could not successfully select the "assign to attorney" dropdown because there were two dropdowns with this option
        click_dropdown(text: "Assign to attorney")
        # click_dropdown(prompt: "Select a user", text: attorney_user_second.full_name)
        # fill_in "taskInstructions", with: "mimic incorrect flow"
        # click_on "Submit"

        # below will fail before fix is made
        # app currently allows the invalid flow of a JudgeAssignTask going from cancelled to complete
        expect(Task.find(first_judge_assign_task_id).status).to eq("cancelled")
      end

      visit "/queue/appeals/#{appeal.uuid}"
      # see what dropdowns are there

      # TODO: test that appeal has multiple JudgeDecisionReviewTasks
      # TODO: test that appeal has multiple AttorneyTasks
    end
  end
end
