require "rails_helper"

RSpec.feature "Judge assignment to attorney" do
  let(:judge) { Judge.new(FactoryBot.create(:user, full_name: "Billie Daniel")) }
  let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
  let(:attorney_one) { FactoryBot.create(:user, full_name: "Moe Syzlak") }
  let(:attorney_two) { FactoryBot.create(:user, full_name: "Alice Macgyvertwo") }
  let(:team_attorneys) { [attorney_one, attorney_two] }
  let(:appeal_one) { FactoryBot.create(:appeal) }
  let(:appeal_two) { FactoryBot.create(:appeal) }

  before do
    create(:staff, :judge_role, user: judge.user)
    team_attorneys.each do |attorney|
      create(:staff, :attorney_role, user: attorney)
      OrganizationsUser.add_user_to_organization(attorney, judge_team)
    end
  end

  before do
    create(:ama_judge_task, :in_progress, assigned_to: judge.user, appeal: appeal_one)
    create(:ama_judge_task, :in_progress, assigned_to: judge.user, appeal: appeal_two)
    User.authenticate!(user: judge.user)
  end

  context "Can move appeals between attorneys" do
    scenario "submits draft decision" do
      visit "/queue"

      find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
      expect(page).to have_content(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL)
      click_on COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL

      expect(page).to have_content("Cases to Assign (2)")
      expect(page).to have_content("Moe Syzlak")
      expect(page).to have_content("Alice Macgyvertwo")

      case_rows = page.find_all("tr[id^='table-row-']")
      expect(case_rows.length).to eq(2)

      # step "checks both cases and assigns them to an attorney"
      scroll_element_in_to_view(".usa-table-borderless")
      check "1", allow_label_click: true
      check "2", allow_label_click: true

      safe_click ".Select"
      click_dropdown(text: attorney_one.full_name)

      click_on "Assign 2 cases"
      expect(page).to have_content("Assigned 2 cases")

      # step "navigates to the attorney's case list"
      click_on "#{attorney_one.full_name} (2)"
      expect(page).to have_content("#{attorney_one.full_name}'s Cases")

      case_rows = page.find_all("tr[id^='table-row-']")
      expect(case_rows.length).to eq(2)

      # step "checks one case and assigns it to another attorney"
      scroll_element_in_to_view(".usa-table-borderless")
      check "3", allow_label_click: true

      safe_click ".Select"
      click_dropdown(text: attorney_two.full_name)

      click_on "Assign 1 case"
      expect(page).to have_content("Assigned 1 case")

      # step "navigates to the other attorney's case list"
      click_on "#{attorney_two.full_name} (1)"
      expect(page).to have_content("#{attorney_two.full_name}'s Cases")

      case_rows = page.find_all("tr[id^='table-row-']")
      expect(case_rows.length).to eq(1)
    end
  end

  context "Can view their queue" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:veteran) { appeal.veteran }
    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }

    context "there's another in-progress JudgeAssignTask" do
      let!(:judge_task) do
        FactoryBot.create(:ama_judge_task, :in_progress, assigned_to: judge.user, appeal: appeal, parent: root_task)
      end

      scenario "viewing the assign task queue" do
        visit "/queue"

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL)
        click_on COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL

        expect(page).to have_content("Assign 3 Cases")
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end
    end

    context "there's an in-progress JudgeDecisionReviewTask" do
      let!(:judge_review_task) do
        FactoryBot.create(
          :ama_judge_decision_review_task, :in_progress, assigned_to: judge.user, appeal: appeal, parent: root_task
        )
      end

      scenario "viewing the review task queue" do
        expect(judge_review_task.status).to eq("in_progress")
        attorney_completed_task = FactoryBot.create(:ama_attorney_task, appeal: appeal, parent: judge_review_task)
        attorney_completed_task.update!(status: Constants.TASK_STATUSES.completed)
        case_review = FactoryBot.create(:attorney_case_review, task_id: attorney_completed_task.id)

        visit "/queue"

        expect(page).to have_content("Review 1 Cases")
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content(case_review.document_id)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end

      scenario "navigating between review and assign task queues" do
        visit "/queue"

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL)
        click_on COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL

        expect(page).to have_current_path("/queue/#{judge.user.id}/assign")
        expect(page).to have_content("Assign 2 Cases")

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(COPY::JUDGE_REVIEW_DROPDOWN_LINK_LABEL)
        click_on COPY::JUDGE_REVIEW_DROPDOWN_LINK_LABEL

        expect(page).to have_current_path("/queue/#{judge.user.id}/review")
        expect(page).to have_content("Review 1 Cases")
      end
    end
  end
end
