# frozen_string_literal: true

RSpec.feature "SpecialtyCaseTeam bulk assignment to attorney", :all_dbs do
  let(:sct_org) { SpecialtyCaseTeam.singleton }

  let!(:attorney) do
    create(:user, :with_vacols_attorney_record, full_name: "Saul Goodman")
  end

  let(:judge) do
    create(:user, :judge, :with_vacols_judge_record, full_name: "Judge Dredd")
  end

  let!(:extra_attorneys) do
    create_list(:user, 5, :with_vacols_attorney_record)
  end

  let(:sct_coordinator) { create(:user, full_name: "SCT Coordinator User", css_id: "SCTUSER") }

  let(:column_heading_names) do
    [
      "Select", "Case Details", "Types", "Docket", "Issues", "Issue Type", "Veteran Documents"
    ]
  end

  let!(:tasks) do
    create_list(:specialty_case_team_assign_task, 5)
  end

  let(:appeals) do
    tasks.map(&:appeal)
  end

  let(:bulk_assign_url) { "/queue/#{sct_coordinator.css_id}/assign?role=sct_coordinator" }

  before do
    sct_org.add_user(sct_coordinator)
    User.authenticate!(user: sct_coordinator)
    judge.administered_judge_teams.first.add_user(attorney)
    judge.save
  end

  context "SCT Coordinator can load the bulk assign page and relevant information" do
    let(:task_first) { tasks.first }
    let(:task_last) { tasks.last }
    scenario "can visit 'Assign' view and assign cases" do
      step "visit assign queue" do
        visit bulk_assign_url
        expect(page).to have_content("Cases to Assign")
        expect(page).to have_content("Assign 0 cases")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(tasks.length)
      end

      step "page errors when cases aren't selected" do
        safe_click ".cf-select"
        click_dropdown(text: attorney.full_name)

        click_on "Assign 0 cases"
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_TASK_TITLE)
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_TASK_DETAIL)
      end

      step "page errors when an attorney/assignee isn't selected" do
        visit bulk_assign_url
        scroll_to(".usa-table-borderless")
        page.find(:css, "input[name='#{task_first.id}']", visible: false).execute_script("this.click()")
        page.find(:css, "input[name='#{task_last.id}']", visible: false).execute_script("this.click()")

        click_on "Assign 2 cases"
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_ASSIGNEE_TITLE)
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL)
      end

      step "cases are assignable when an attorney/assignee and tasks are selected" do
        safe_click ".cf-select"
        click_dropdown(text: attorney.full_name)

        click_on "Assign 2 cases"
        expect(page).to have_content("Assigned 2 tasks to #{attorney.full_name}")
        # Check the button to make sure it reset back to 0
        expect(page).to have_content("Assign 0 cases")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(3)

        task_first.reload
        task_last.reload
        first_judge_task = task_first.parent.children.of_type(:JudgeDecisionReviewTask).first
        first_attorney_task = first_judge_task.children.of_type(:AttorneyTask).first
        last_judge_task = task_last.parent.children.of_type(:JudgeDecisionReviewTask).first
        last_attorney_task = last_judge_task.children.of_type(:AttorneyTask).first

        expect(task_first.status).to eq("completed")
        expect(first_attorney_task.status).to eq("assigned")
        expect(first_attorney_task.assigned_to).to eq(attorney)
        expect(first_attorney_task.assigned_by).to eq(judge)
        expect(first_judge_task.assigned_to).to eq(judge)
        expect(first_judge_task.assigned_by).to eq(sct_coordinator)
        expect(first_judge_task.status).to eq("on_hold")

        expect(task_last.status).to eq("completed")
        expect(last_attorney_task.status).to eq("assigned")
        expect(last_attorney_task.assigned_to).to eq(attorney)
        expect(last_attorney_task.assigned_by).to eq(judge)
        expect(last_judge_task.assigned_to).to eq(judge)
        expect(last_judge_task.assigned_by).to eq(sct_coordinator)
        expect(last_judge_task.status).to eq("on_hold")
      end
    end
  end
end
