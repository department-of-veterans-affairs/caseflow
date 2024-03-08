# frozen_string_literal: true

require_relative "./queue_shared_examples_spec.rb"

feature "SpecialtyCaseTeamQueue", :all_dbs do
  context "Load Specialty Case Team Queue" do
    let!(:sct_org) { SpecialtyCaseTeam.singleton }
    let!(:sct_user) { User.authenticate!(roles: ["Admin Intake"]) }

    let!(:action_required_tab_text) { "Action Required" }
    let!(:completed_tab_text) { "Completed" }

    let(:column_heading_names) do
      [
        "Case Details", "Types", "Docket", "Issues", "Issue Type", "Veteran Documents"
      ]
    end

    let(:num_action_required_rows) { 3 }
    let(:num_completed_rows) { 9 }

    let!(:sct_action_required_tasks) do
      create_list(:specialty_case_team_assign_task, num_action_required_rows, :action_required)
    end
    let!(:sct_completed_tasks) do
      tasks = create_list(:specialty_case_team_assign_task, num_completed_rows, :completed)
      tasks.last.closed_at = 13.days.ago
      tasks.last.save
    end

    let!(:action_required_issues) do
      [
        create(:request_issue, :nonrating,
               decision_review: sct_action_required_tasks.first.appeal,
               nonrating_issue_category: "Medical and Dental Care Reimbursement", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: sct_action_required_tasks.first.appeal,
               nonrating_issue_category: "Foreign Medical Program", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: sct_action_required_tasks.first.appeal,
               nonrating_issue_category: "Beneficiary Travel", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: sct_action_required_tasks.first.appeal,
               nonrating_issue_category: "Foreign Medical Program", benefit_type: "vha")
      ]
    end

    before do
      FeatureToggle.enable!(:specialty_case_team_distribution)
      sct_org.add_user(sct_user)
      sct_user.reload
      visit "/organizations/#{sct_org.url}"
    end

    # Setup variables for the Standard Queue feature tests shared examples
    let!(:tabs) do
      test_tab = Struct.new(:tab_name, :tab_columns, :tab_body_text, :number_of_tasks)
      [
        test_tab.new(
          action_required_tab_text, column_heading_names,
          "Cases owned by the Specialty Case Team that require action:",
          3
        ),
        test_tab.new(
          completed_tab_text, column_heading_names,
          "Cases owned by the Specialty Case Team that have been assigned to a SCT Attorney (last 14 days):",
          9
        )
      ]
    end

    let!(:queue) { Struct.new(:tabs).new(tabs) }

    include_examples "Standard Queue feature tests"

    context "Specialty Case Team Queue" do
      let!(:attorney) do
        create(:user, :with_vacols_attorney_record, full_name: "Saul Goodman")
      end

      let(:judge) do
        create(:user, :judge, :with_vacols_judge_record, full_name: "Judge Dredd")
      end

      let(:appeal) { sct_action_required_tasks.first.appeal }

      let(:case_details_page_url) { "/queue/appeals/#{appeal.uuid}" }

      before do
        judge.administered_judge_teams.first.add_user(attorney)
        judge.save
      end

      scenario "Specialty Case Team Queue Loads correctly" do
        expect(find("h1")).to have_content("Specialty Case Team cases")
      end

      scenario "SCT action required tab displays multiple issue types ordered in ascending order and no duplicates" do
        expect(page).to have_content(
          /\nBeneficiary Travel\nCaregiver | Other\nForeign Medical Program\nMedical and Dental Care Reimbursement\n/
        )
      end

      scenario "Task action: Assign to attorney" do
        visit case_details_page_url
        expect(page).to have_content("Currently active tasks")
        page.find(".cf-select")
        click_dropdown(text: "Assign to attorney")
        within ".cf-modal" do
          expect(page).to have_content("Assign task")
          page.find(".cf-select__placeholder", text: "Search or select").click
          click_dropdown(text: attorney.full_name)
          page.find("#taskInstructions").set("This is a test")
          click_button COPY::ASSIGN_TASK_BUTTON
        end

        expect(page).to have_content("Specialty Case Team cases")
        expect(page).to have_content("You have successfully assigned 1 case to")
        expect(current_path).to eq("/organizations/specialty-case-team")
      end
    end
  end
end
