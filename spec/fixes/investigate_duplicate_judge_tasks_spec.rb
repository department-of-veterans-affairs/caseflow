# frozen_string_literal: true

feature "duplicate JudgeAssignTask investigation" do
  before do
    User.authenticate!(user: judge_user)
  end

  # Ticket: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/212#
  # Desired Target state: JudgeAssignTask should not change status from cancelled to completed
  describe "Judge reassigns JudgeAssignTask in first tab and completes the same task in second tab" do
    let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Anna Juarez") }
    let!(:judge_staff) { create(:staff, :judge_role, user: judge_user) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge_user) }
    let(:judge_user_second) do
      create(:user, station_id: User::BOARD_STATION_ID, css_id: "BVAAABSHIRE",
                    full_name: "Aaron Judge_HearingsAndCases Abshire")
    end
    let!(:judge_staff_second) { create(:staff, :judge_role, user: judge_user_second) }

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
      visit "/queue/appeals/#{uuid}"
      expect(page).to have_content(appeal.veteran.first_name, wait: 30)
      appeal.reload.treee

      # open a second window and visit case details page, window B
      second_window = open_new_window
      within_window second_window do
        visit "/queue/appeals/#{uuid}"
        expect(page).to have_content(appeal.veteran.first_name, wait: 30)
      end

      # in window A, reassign the JudgeAssignTask to another judge
      binding.pry
      first_judge_assign_task_id = appeal.tasks.select { |task| task.type == "JudgeAssignTask" }[0].id
      click_dropdown(prompt: "Select an action", text: "Re-assign to a judge")
      click_dropdown(prompt: "Select a user", text: judge_user_second.full_name)
      fill_in "taskInstructions", with: "reassign this task! teamwork makes the dreamwork!"
      click_on "Submit"
      expect(page).to have_content(appeal.veteran.first_name, wait: 30)
      appeal.reload.treee

      binding.pry
      expect(page).to have_content(COPY::REASSIGN_TASK_SUCCESS_MESSAGE, judge_user_second.full_name)
      expect(Task.find(first_judge_assign_task_id).status).to eq("cancelled")
      visit "/queue/appeals/#{uuid}"

      # in window B, complete the JudgeAssignTask
      within_window second_window do
        click_dropdown(prompt: "Select an action", text: "Assign to attorney")
        click_dropdown(prompt: "Select a user", text: "Other")
        click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
        fill_in "taskInstructions", with: "assign to attorney"
        click_on "Submit"
        appeal.reload.treee

        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, attorney_user.full_name)

        visit "/queue/appeals/#{uuid}"
        # Complete JudgeAssignTask to create an invalid number of AttorneyTasks
        click_dropdown(prompt: "Select an action", text: "Assign to attorney")
        click_dropdown(prompt: "Select a user", text: "Other")
        click_dropdown(prompt: "Select a user", text: attorney_user_second.full_name)
        fill_in "taskInstructions", with: "mimic incorrect flow"
        click_on "Submit"
        expect(page).to have_content(appeal.veteran.first_name, wait: 30)
        appeal.reload.treee

        # BUG FIX: app should no longer allow the invalid flow of a JudgeAssignTask going from cancelled to completed
        expect(Task.find(first_judge_assign_task_id).status).to eq("cancelled")
      end

      visit "/queue/appeals/#{uuid}"
      appeal.reload.treee
    end
  end
end
