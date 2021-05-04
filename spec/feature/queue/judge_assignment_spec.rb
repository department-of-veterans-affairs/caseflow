# frozen_string_literal: true

RSpec.feature "Judge assignment to attorney and judge", :all_dbs do
  let(:judge_one) { Judge.new(create(:user, full_name: "Billie Daniel")) }
  let(:judge_two) { Judge.new(create(:user, full_name: "Joe Shmoe")) }
  let!(:vacols_user_one) { create(:staff, :judge_role, user: judge_one.user) }
  let!(:vacols_user_two) { create(:staff, :judge_role, user: judge_two.user) }
  let!(:judge_one_team) { JudgeTeam.create_for_judge(judge_one.user) }
  let!(:judge_two_team) { JudgeTeam.create_for_judge(judge_two.user) }
  let(:attorney_one) { create(:user, full_name: "Moe Syzlak") }
  let(:attorney_two) { create(:user, full_name: "Alice Macgyvertwo") }
  let(:team_attorneys) { [attorney_one, attorney_two] }
  let(:appeal_one) { create(:appeal) }
  let(:appeal_two) { create(:appeal) }

  before do
    team_attorneys.each do |attorney|
      create(:staff, :attorney_role, user: attorney)
      judge_one_team.add_user(attorney)
    end

    User.authenticate!(user: judge_one.user)
  end

  context "Acting judge can see team and other users load" do
    let!(:vacols_user_one_acting_judge) { create(:staff, :attorney_judge_role, user: judge_one.user) }

    scenario "visits 'Assign' view" do
      visit "/queue"

      find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
      expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))
      click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id)

      expect(page).to have_content("Cases to Assign")
      expect(page).to have_content("Moe Syzlak")
      expect(page).to have_content("Alice Macgyvertwo")

      click_dropdown(text: "Other")
      safe_click ".dropdown-Other"
      # expect attorneys and acting judges but not judges
      expect(page.find(".dropdown-Other")).to have_content judge_one.user.full_name
      expect(page.find(".dropdown-Other")).to have_no_content judge_two.user.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_one.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_two.full_name
    end
  end

  context "Can move appeals between attorneys" do
    scenario "submits draft decision" do
      judge_task_one = create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
      judge_task_two = create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_two)

      visit "/queue"

      find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
      expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))
      click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id)

      expect(page).to have_content("Cases to Assign (2)")
      expect(page).to have_content("Moe Syzlak")
      expect(page).to have_content("Alice Macgyvertwo")

      case_rows = page.find_all("tr[id^='table-row-']")
      expect(case_rows.length).to eq(2)

      step "checks both cases and assigns them to an attorney" do
        scroll_to(".usa-table-borderless")
        page.find(:css, "input[name='#{judge_task_one.id.to_s}']", visible: false).execute_script("this.click()")
        page.find(:css, "input[name='#{judge_task_two.id.to_s}']", visible: false).execute_script("this.click()")

        safe_click ".cf-select"
        click_dropdown(text: attorney_one.full_name)

        click_on "Assign 2 cases"
        expect(page).to have_content("Assigned 2 tasks to #{attorney_one.full_name}")
      end

      step "navigates to the attorney's case list" do
        click_on "#{attorney_one.full_name} (2)"
        expect(page).to have_content("#{attorney_one.full_name}'s Cases")

        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(2)
      end

      step "checks one case and assigns it to another attorney" do
        scroll_to(".usa-table-borderless")
        page.find(:css, "input[name='#{attorney_one.tasks.first.id.to_s}']", visible: false).execute_script("this.click()")

        safe_click ".cf-select"
        click_dropdown(text: attorney_two.full_name)

        click_on "Assign 1 case"
        expect(page).to have_content("Reassigned 1 task to #{attorney_two.full_name}")
      end

      step "navigates to the other attorney's case list" do
        click_on "#{attorney_two.full_name} (1)"
        expect(page).to have_content("#{attorney_two.full_name}'s Cases")

        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(1)
      end
    end
  end

  context "Cannot view assigned cases queue of attorneys in other teams" do
    shared_examples "accessing assigned queue for attorney in other team" do
      it "fails visiting other attorney's assigned cases page" do
        visit "/queue/#{judge_two.user.css_id}/assign/#{attorney_one.id}"
        expect(page).to have_content("Attorney is not part of the specified judge's team.")

        visit "/queue/#{judge_one.user.css_id}/assign/#{attorney_one.id}"
        expect(page).to have_content("Additional access needed")
      end
    end

    before { User.authenticate!(user: judge_two.user) }
    context "attempt to view other team's attorney's cases" do
      include_examples "accessing assigned queue for attorney in other team"

      it "allows visiting own case assign page" do
        visit "/queue/#{judge_two.user.css_id}/assign"
        expect(page).to have_content("Assign 0 Cases")
      end

      it "succeeds after user is added to SpecialCaseMovementTeam" do
        SpecialCaseMovementTeam.singleton.add_user(judge_two.user)
        visit "/queue/#{judge_two.user.css_id}/assign/#{attorney_one.id}"
        expect(page).to have_content("Attorney is not part of the specified judge's team.")

        visit "/queue/#{judge_one.user.css_id}/assign/#{attorney_one.id}"
        expect(page).to have_content("#{attorney_one.full_name}'s Cases")
      end
    end
  end

  context "Can view their queue" do
    let(:appeal) { create(:appeal) }
    let(:veteran) { appeal.veteran }
    let!(:root_task) { create(:root_task, appeal: appeal) }

    before do
      create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
      create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_two)
    end

    context "there's another in-progress JudgeAssignTask" do
      let!(:judge_task) do
        create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, parent: root_task)
      end

      scenario "viewing the assign task queue" do
        visit "/queue"

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))
        click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id)

        expect(page).to have_content("Assign 3 Cases")
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end
    end

    context "there's an in-progress JudgeDecisionReviewTask" do
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :in_progress, assigned_to: judge_one.user, parent: root_task)
      end

      scenario "viewing the review task queue" do
        expect(judge_review_task.status).to eq("in_progress")
        attorney_completed_task = create(:ama_attorney_task, parent: judge_review_task)
        attorney_completed_task.update!(status: Constants.TASK_STATUSES.completed)
        case_review = create(:attorney_case_review, task_id: attorney_completed_task.id)

        visit "/queue"

        expect(page).to have_content("Your cases")
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content(case_review.document_id)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end

      scenario "navigating between review and assign task queues" do
        visit "/queue"

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))
        click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id)

        expect(page).to have_current_path("/queue/#{judge_one.user.css_id}/assign")
        expect(page).to have_content("Assign 2 Cases")

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(COPY::JUDGE_REVIEW_DROPDOWN_LINK_LABEL)
        click_on COPY::JUDGE_REVIEW_DROPDOWN_LINK_LABEL

        expect(page).to have_current_path("/queue")
        expect(page).to have_content("Your cases")
      end
    end
  end

  context "Encounters an error assigning a case" do
    scenario "when assigning from their assign queue" do
      judge_task_one = create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
      judge_task_two = create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_two)
      create(:ama_judge_decision_review_task, assigned_to: judge_one.user, appeal: appeal_two)

      step "visits their assign queue" do
        visit "/queue/#{judge_one.user.css_id}/assign"

        expect(page).to have_content("#{attorney_one.full_name} (0)")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(2)
      end

      step "checks both cases and assigns them to an attorney" do
        scroll_to(".usa-table-borderless")
        page.find(:css, "input[name='#{judge_task_one.id.to_s}']", visible: false).execute_script("this.click()")
        page.find(:css, "input[name='#{judge_task_two.id.to_s}']", visible: false).execute_script("this.click()")

        safe_click ".cf-select"
        click_dropdown(text: attorney_one.full_name)

        click_on "Assign 2 cases"
        expect(page).to have_content("#{attorney_one.full_name} (0)")
        expect(page).to have_content("Error assigning tasks")
        expect(page).to have_content("Docket (#{appeal_two.docket_number}) already "\
                                     "has an open task type of #{JudgeDecisionReviewTask.name}")

        visit "/queue/#{judge_one.user.css_id}/assign"
        expect(page).to have_content("#{attorney_one.full_name} (0)")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(2)
      end
    end
  end

  describe "Reassigning a legacy appeal to another judge from the case details page" do
    let!(:vacols_case) { create(:case, staff: vacols_user_one) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let!(:decass) { create(:decass, defolder: vacols_case.bfkey) }

    it "should allow us to assign a case to a judge from the case details page" do
      visit("/queue/#{judge_one.user.id}/assign")
      expect(page).to have_content("#{appeal.veteran_first_name} #{appeal.veteran_last_name}")
      expect(page).to have_content("Cases to Assign (1)")
      click_on("#{appeal.veteran_first_name} #{appeal.veteran_last_name}")

      click_dropdown(text: Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.label)
      click_dropdown(prompt: "Select a user", text: judge_two.user.full_name)
      fill_in("taskInstructions", with: "Test")
      click_on("Submit")

      expect(page).to have_content("Task reassigned to #{judge_two.user.full_name}")

      click_on("Switch views")
      click_on(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))

      expect(page).to_not have_content("#{appeal.veteran_first_name} #{appeal.veteran_last_name}")
      expect(page).to have_content("Cases to Assign (0)")

      User.authenticate!(user: judge_two.user)
      visit("/queue/#{judge_two.user.id}/assign")
      expect(page).to have_content("Cases to Assign (1)")
      expect(page).to have_content("#{appeal.veteran_first_name} #{appeal.veteran_last_name}")
    end
  end

  describe "Assigning a legacy appeal to an attorney from the case details page" do
    let!(:vacols_case) { create(:case, staff: vacols_user_one) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let!(:decass) { create(:decass, defolder: vacols_case.bfkey) }

    it "should allow us to assign a case to an attorney from the case details page" do
      visit("/queue/appeals/#{appeal.external_id}")

      click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.label)
      click_dropdown(prompt: "Select a user", text: attorney_one.full_name)
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")
      click_on("Submit")

      expect(page).to have_content("Assigned 1 task to #{attorney_one.full_name}")
    end
  end

  describe "Reassigning an ama appeal to a judge from the case details page" do
    before do
      create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
    end

    it "should allow us to assign a case to a judge from the case details page" do
      visit("/queue/#{judge_one.user.id}/assign")
      expect(page).to have_content("Cases to Assign (1)")
      click_on("#{appeal_one.veteran_first_name} #{appeal_one.veteran_last_name}")

      click_dropdown(text: Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.label)
      click_dropdown(prompt: "Select a user", text: judge_two.user.full_name)
      fill_in("taskInstructions", with: "Test")
      click_on("Submit")

      click_on("Switch views")
      click_on(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_one.user.css_id))

      expect(page).to_not have_content("#{appeal_one.veteran_first_name} #{appeal_one.veteran_last_name}")
      expect(page).to have_content("Cases to Assign (0)")

      User.authenticate!(user: judge_two.user)
      visit("/queue/#{judge_two.user.id}/assign")
      expect(page).to have_content("Cases to Assign (1)")
      expect(page).to have_content("#{appeal_one.veteran_first_name} #{appeal_one.veteran_last_name}")
    end
  end

  describe "Assigning an AttorneyTask to an acting judge from the case details page" do
    let!(:vacols_user_two) { create(:staff, :attorney_judge_role, user: judge_two.user) }

    before do
      create(:ama_judge_assign_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
    end

    it "should allow us to assign an ama appeal to an acting judge from the 'Assign to attorney' action'" do
      visit("/queue/appeals/#{appeal_one.external_id}")

      click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.label)
      click_dropdown(prompt: "Select a user", text: "Other")
      safe_click ".dropdown-Other"
      click_dropdown({ text: judge_two.user.full_name }, page.find(".dropdown-Other"))
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")

      click_on("Submit")
      expect(page).to have_content("Assigned 1 task to #{judge_two.user.full_name}")
    end
  end

  describe "requesting cases (automatic case distribution)" do
    before do
      allow_any_instance_of(DirectReviewDocket)
        .to receive(:nonpriority_receipts_per_year)
        .and_return(100)

      allow(Docket)
        .to receive(:nonpriority_decisions_per_year)
        .and_return(1000)

      allow_any_instance_of(LegacyDocket).to receive(:weight).and_return(101.4)
      allow_any_instance_of(DirectReviewDocket).to receive(:weight).and_return(10)
    end

    it "displays an error if the distribution request is invalid" do
      create(:ama_judge_assign_task, assigned_at: 40.days.ago, assigned_to: judge_one.user, appeal: appeal_one)

      visit("/queue/#{judge_one.user.id}/assign")
      click_on("Request more cases")
      find_button("Request more cases")

      expect(page).to have_content("Cases in your queue are waiting to be assigned")
    end

    it "queues the case distribution if the request is valid" do
      create(:ama_judge_assign_task, assigned_at: 10.days.ago, assigned_to: judge_one.user, appeal: appeal_one)

      visit("/queue/#{judge_one.user.id}/assign")
      click_on("Request more cases")

      expect(page).to have_content("Distribution complete")
    end
  end
end
