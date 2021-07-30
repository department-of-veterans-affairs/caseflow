

feature "duplicate JudgeAssignTask investigation" do
  before do
    User.authenticate!(css_id: "BVAAABSHIRE")
  end

  # Ticket: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/212#
  # Target state: there should be no more than 1 open JudgeAssignTask
  describe "Judge reassigns JudgeAssignTask in first tab and complete task in second tab" do
    let(:judge) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
  
    let(:attorney) { create(:user, :with_vacols_attorney_record) }
    let(:appeal) { create(:appeal, :at_attorney_drafting, associated_judge: judge, associated_attorney: attorney) }

    scenario "Caseflow creates multiple JudgeDecisionReview and JudgeAssign tasks" do
      # open a window and visit case details page, window A
      visit "/queue/appeals/#{appeal.uuid}"
      binding.pry

      # open a second window and visit case details page, window B
      second_window = open_new_window
      within_window second_window do
        visit "/queue/appeals/#{appeal.uuid}"
      end

      # in window A, reassign the JudgeAssignTask to another judge 
      # window A: expect message - task reassigned
      click_dropdown(prompt: "Select an action", text: "Re-assign to a judge")
      expect(page).to have_content(COPY::REASSIGN_TASK_SUCCESS_MESSAGE)
      first_judge_assign_task = appeal.tasks.select{ |task| task.type == "JudgeAssignTask" }[0]
      # test that JudgeAssignTask is cancelled
      expect(first_judge_assign_task.status).to eq("cancelled")

      within_window second_window do
        # in window B, complete the JudgeAssignTask
        # window B: expect message - attorney now has task
        click_dropdown(prompt: "Select an action", text: "Assign to attorney")
        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE)

        # below will fail before fix is made - app currently allows the invalid flow of a JudgeAssignTask going from cancelled to complete
        expect(first_judge_assign_task.status).to eq("cancelled")
      end

      appeal.reload

      # test that appeal has multiple JudgeAssignTasks
      # test that appeal has multiple JudgeDecisionReviewTasks
      # test that appeal has multiple AttorneyTasks
    end
  end
end