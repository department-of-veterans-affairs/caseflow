# frozen_string_literal: true

RSpec.feature "SCM Team access to judge movement features", :all_dbs do
  let(:judge_one) { Judge.new(create(:user, full_name: "Billie Daniel")) }
  let(:judge_two) { Judge.new(create(:user, full_name: "Joe Shmoe")) }
  let(:acting_judge) { Judge.new(create(:user, full_name: "Acting Judge")) }
  let!(:vacols_user_one) { create(:staff, :judge_role, user: judge_one.user) }
  let!(:vacols_user_two) { create(:staff, :judge_role, user: judge_two.user) }
  let!(:vacols_user_acting) { create(:staff, :attorney_judge_role, user: acting_judge.user) }
  let!(:judge_one_team) { JudgeTeam.create_for_judge(judge_one.user) }
  let!(:judge_two_team) { JudgeTeam.create_for_judge(judge_two.user) }
  let(:attorney_one) { create(:user, full_name: "Moe Syzlak") }
  let(:attorney_two) { create(:user, full_name: "Alice Macgyvertwo") }
  let(:team_attorneys) { [attorney_one, attorney_two] }

  let!(:scm_user) { create(:user, full_name: "Rosalie SCM Dunkle") }
  let!(:scm_staff) { create(:staff, user: scm_user) }
  let(:current_user) { scm_user }

  before do
    team_attorneys.each do |attorney|
      create(:staff, :attorney_role, user: attorney, stitle: "DF")
      judge_one_team.add_user(attorney)
    end

    SpecialCaseMovementTeam.singleton.add_user(scm_user)
    User.authenticate!(user: current_user)
  end

  context "Non-SCM user should not see judge assign queue page if they are not the judge" do
    context "logged in user is some user" do
      let(:current_user) { create(:user, full_name: "Odd ManOutthree") }

      scenario "visits 'Assign' view" do
        [judge_one.user.id, judge_one.user.css_id].each do |user_id_path|
          visit "/queue/#{user_id_path}/assign"
          expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
        end
      end
    end
    context "logged in user is attorney on the team" do
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        [judge_one.user.id, judge_one.user.css_id].each do |user_id_path|
          visit "/queue/#{user_id_path}/assign"
          expect(page).to have_content("Additional access needed")
        end
      end
    end
    context "logged in user is attorney on the team with judge role" do
      let!(:vacols_atty_one_acting_judge) { create(:staff, :attorney_judge_role, user: attorney_one) }
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        [judge_one.user.id, judge_one.user.css_id].each do |user_id_path|
          visit "/queue/#{user_id_path}/assign"
          expect(page).to have_content("Additional access needed")
        end
      end
    end
  end

  context "SCM user can view judge's queue" do
    let!(:appeal) { create(:appeal, :assigned_to_judge, associated_judge: judge_one.user) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, staff: vacols_user_one)) }

    scenario "with both ama and legacy case" do
      [judge_one.user.id, judge_one.user.css_id].each do |user_id_path|
        visit "/queue/#{user_id_path}/assign"

        expect(page).to have_content("Assign 2 Cases for #{judge_one.user.css_id}")

        expect(page).to have_content("#{appeal.veteran.first_name} #{appeal.veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)

        expect(page).to have_content("#{legacy_appeal.veteran_first_name} #{legacy_appeal.veteran_last_name}")
        expect(page).to have_content(legacy_appeal.veteran_file_number)
        expect(page).to have_content(legacy_appeal.docket_number)

        expect(page).to have_content("Cases to Assign")
        expect(page).to have_content("Moe Syzlak")
        expect(page).to have_content("Alice Macgyvertwo")

        expect(page.find(".usa-sidenav-list")).to have_content attorney_one.full_name
        expect(page.find(".usa-sidenav-list")).to have_content attorney_two.full_name

        safe_click ".cf-select"
        expect(page.find(".dropdown-Assignee")).to have_content attorney_one.full_name
        expect(page.find(".dropdown-Assignee")).to have_content attorney_two.full_name

        click_dropdown(text: "Other")
        safe_click ".dropdown-Other"
        # expect attorneys and acting judges but not judges
        expect(page.find(".dropdown-Other")).to have_content acting_judge.user.full_name
        expect(page.find(".dropdown-Other")).to have_no_content judge_one.user.full_name
        expect(page.find(".dropdown-Other")).to have_no_content judge_two.user.full_name
        expect(page.find(".dropdown-Other")).to have_content attorney_one.full_name
        expect(page.find(".dropdown-Other")).to have_content attorney_two.full_name

        expect(page).to have_content "Request more cases"
      end
    end

    context "can perform the same case movement actions as a judge" do
      let!(:appeal) { create(:appeal, :ready_for_distribution) }
      let!(:review_appeal) do
        create(:appeal, :at_judge_review, associated_judge: judge_one.user, associated_attorney: attorney_one)
      end
      let(:assigner_name) { "#{scm_user.full_name.split(' ').first.first}. #{scm_user.full_name.split(' ').last}" }

      before do
        allow_any_instance_of(LegacyDocket).to receive(:weight).and_return(101.4)
        allow_any_instance_of(DirectReviewDocket).to receive(:weight).and_return(10)
        allow_any_instance_of(DirectReviewDocket).to receive(:nonpriority_receipts_per_year).and_return(100)
        allow(Docket).to receive(:nonpriority_decisions_per_year).and_return(1000)
      end

      scenario "on ama appeals" do
        step "request cases" do
          visit "/queue/#{judge_one.user.css_id}/assign"

          expect(page).to have_content("Assign 1 Cases for #{judge_one.user.css_id}")
          expect(page).to_not have_content("#{appeal.veteran.first_name} #{appeal.veteran.last_name}")

          click_on("Request more cases")
          expect(page).to have_content("Distribution complete")

          expect(page).to have_content("Assign 2 Cases for #{judge_one.user.css_id}")

          expect(page).to have_content(appeal.veteran_file_number)
          expect(page).to have_content("Original")
          expect(page).to have_content(appeal.docket_number)
        end

        step "reassign a JudgeAssignTask" do
          click_on(appeal.veteran_file_number)

          expect(page).to have_content("ASSIGNED TO\n#{judge_one.user.css_id}")
          click_dropdown(propmt: "Select an action...", text: "Re-assign to a judge")
          click_dropdown(prompt: "Select a user", text: judge_two.user.full_name)
          instructions = "#{judge_one.user.full_name} is on leave. Please take over this case"
          fill_in("taskInstructions", with: instructions)
          click_on("Submit")

          expect(page).to have_content("Task reassigned to #{judge_two.user.full_name}")

          visit "/queue/appeals/#{appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{judge_two.user.css_id}")
          expect(page).to have_content("ASSIGNED BY\n#{assigner_name}")
          expect(page).to have_content("TASK\n#{JudgeAssignTask.label}")
          click_on("View task instructions")
          expect(page).to have_content(instructions)
        end

        step "assign an AttorneyTask" do
          click_dropdown(propmt: "Select an action...", text: "Assign to attorney")
          click_dropdown(prompt: "Select a user", text: "Other")
          click_dropdown(prompt: "Select a user", text: attorney_one.full_name)
          instructions = "#{judge_one.user.full_name} is on leave. Please draft a decision for this case"
          fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions)
          binding.pry
          click_on("Submit")

          expect(page).to have_content("Assigned 1 task to #{attorney_one.full_name}")

          visit "/queue/appeals/#{appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{attorney_one.css_id}")
          expect(page).to have_content("ASSIGNED BY\n#{assigner_name}")
          expect(page).to have_content("TASK\n#{AttorneyTask.label}")
          expect(page).to have_content("TASK\n#{JudgeDecisionReviewTask.label}")
          expect(page).not_to have_content("TASK\n#{JudgeAssignTask.label}")
          click_on("View task instructions")
          expect(page).to have_content(instructions)
        end

        step "reassign an AttorneyTask" do
          click_dropdown(propmt: "Select an action...", text: "Assign to attorney")
          click_dropdown(prompt: "Select a user", text: "Other")
          click_dropdown(prompt: "Select a user", text: attorney_two.full_name)
          click_on("Submit")

          expect(page).to have_content("Reassigned 1 task to #{attorney_two.full_name}")

          visit "/queue/appeals/#{appeal.external_id}"
          active_tasks_section = page.find("#currently-active-tasks")
          expect(active_tasks_section).not_to have_content("ASSIGNED TO\n#{attorney_one.css_id}")
          expect(active_tasks_section).to have_content("ASSIGNED TO\n#{attorney_two.css_id}")
          expect(active_tasks_section).to have_content("ASSIGNED BY\n#{assigner_name}")
        end

        step "cancel an AttorneyTask" do
          click_dropdown(propmt: "Select an action...", text: "Cancel task")
          expect(page).to have_content(format(COPY::CANCEL_TASK_MODAL_DETAIL, judge_two.user.full_name))
          fill_in "taskInstructions", with: "Sending back to judge to be reassigned"
          click_on("Submit")
          expect(page).to have_content(
            "Task for #{appeal.veteran.first_name} #{appeal.veteran.last_name}'s case has been cancelled"
          )

          visit "/queue/appeals/#{appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{judge_two.user.css_id}")
          expect(page).to have_content("ASSIGNED BY\n#{assigner_name}")
          expect(page).to have_content("TASK\n#{JudgeAssignTask.label}")
          expect(page).to have_content("CANCELLED BY\n#{scm_user.css_id}")
        end

        step "reassign a JudgeDecisionReviewTask" do
          visit "/queue/appeals/#{review_appeal.external_id}"

          expect(page).to have_content("ASSIGNED TO\n#{judge_one.user.css_id}")
          expect(page).to have_content("TASK\n#{JudgeDecisionReviewTask.label}")
          click_dropdown(propmt: "Select an action...", text: "Re-assign to a judge")
          click_dropdown(prompt: "Select a user", text: judge_two.user.full_name)
          fill_in("taskInstructions", with: "#{judge_one.user.full_name} is on leave. Please take over this case")
          click_on("Submit")

          expect(page).to have_content("Task reassigned to #{judge_two.user.full_name}")

          visit "/queue/appeals/#{review_appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{judge_two.user.css_id}")
          expect(page).to have_content("ASSIGNED BY\n#{assigner_name}")
          expect(page).to have_content("TASK\n#{JudgeDecisionReviewTask.label}")
        end
      end

      scenario "on legacy appeals" do
        step "reassign a JudgeLegacyAssignTask" do
          visit "/queue/#{judge_one.user.css_id}/assign"
          click_on(legacy_appeal.veteran_file_number)

          expect(page).to have_content("ASSIGNED TO\n#{judge_one.user.vacols_uniq_id}")
          click_dropdown(propmt: "Select an action...", text: "Re-assign to a judge")
          click_dropdown(prompt: "Select a user", text: judge_two.user.full_name)
          fill_in("taskInstructions", with: "#{judge_one.user.full_name} is on leave. Please take over this case")
          click_on("Submit")

          expect(page).to have_content("Task reassigned to #{judge_two.user.full_name}")

          visit "/queue/appeals/#{legacy_appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{judge_two.user.vacols_uniq_id}")
          expect(page).to have_content("TASK\n#{COPY::JUDGE_ASSIGN_TASK_LABEL}")
          visit "/queue/#{judge_two.user.css_id}/assign"
          click_on(legacy_appeal.veteran_file_number)
        end

        step "assign an AttorneyTask" do
          click_dropdown(propmt: "Select an action...", text: "Assign to attorney")
          click_dropdown(prompt: "Select a user", text: "Other")
          click_dropdown(prompt: "Select a user", text: attorney_one.full_name)
          instructions = "#{judge_one.user.full_name} is on leave. Please draft a decision for this case"
          fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions)
          click_on("Submit")

          expect(page).to have_content("Assigned 1 task to #{attorney_one.full_name}")

          visit "/queue/appeals/#{legacy_appeal.external_id}"
          expect(page).to have_content("ASSIGNED TO\n#{attorney_one.vacols_uniq_id}")
          expect(page).to have_content("ASSIGNED BY\n#{assigner_name}")
          expect(page).to have_content("TASK\n#{COPY::ATTORNEY_TASK_LABEL}")
        end
      end
    end
  end
end
