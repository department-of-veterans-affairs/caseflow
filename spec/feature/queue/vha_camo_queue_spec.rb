# frozen_string_literal: true

require_relative "./queue_shared_examples_spec.rb"

feature "CamoQueue", :all_dbs do
  context "Load CAMO Queue" do
    let!(:camo_org) { VhaCamo.singleton }
    let!(:camo_user) { User.authenticate!(roles: ["Admin Intake"]) }

    let(:assigned_tab_text) { "Assigned" }
    let(:in_progress_tab_text) { "In Progress" }
    let(:completed_tab_text) { "Completed" }

    let(:column_heading_names) do
      [
        "Case Details", "Issue Type", "Tasks", "Issues", "Days Waiting", "Types", "Assigned To"
      ]
    end
    let(:num_assigned_rows) { 3 }
    let(:num_in_progress_rows) { 9 }
    let(:num_completed_rows) { 5 }

    let!(:vha_camo_assigned_tasks) do
      create_list(:vha_document_search_task, num_assigned_rows, :assigned, assigned_to: camo_org)
    end
    let!(:vha_camo_in_progress_tasks) do
      create_list(:vha_document_search_task, num_in_progress_rows, :in_progress, assigned_to: camo_org)
    end
    let!(:vha_camo_completed_tasks) do
      create_list(:vha_document_search_task, num_completed_rows, :completed, assigned_to: camo_org)
    end

    let!(:assigned_request_issues) do
      [
        create(:request_issue, :nonrating,
               decision_review: vha_camo_assigned_tasks.first.appeal,
               nonrating_issue_category: "Spina Bifida Treatment (Non-Compensation)", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: vha_camo_assigned_tasks.first.appeal,
               nonrating_issue_category: "Foreign Medical Program", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: vha_camo_assigned_tasks.first.appeal,
               nonrating_issue_category: "Beneficiary Travel", benefit_type: "vha"),
        create(:request_issue, :nonrating,
               decision_review: vha_camo_assigned_tasks.first.appeal,
               nonrating_issue_category: "Foreign Medical Program", benefit_type: "vha")
      ]
    end

    before do
      camo_org.add_user(camo_user)
      camo_user.reload
      visit "/organizations/#{camo_org.url}"
    end

    # Setup variables for the Standard Queue feature tests shared examples
    let!(:tabs) do
      test_tab = Struct.new(:tab_name, :tab_columns, :tab_body_text, :number_of_tasks)
      [
        test_tab.new(assigned_tab_text, column_heading_names, "Cases assigned to you:", 12),
        test_tab.new(in_progress_tab_text, column_heading_names, "Cases that are in progress:", 0),
        test_tab.new(completed_tab_text, column_heading_names, "Cases assigned to you:", 5)
      ]
    end
    let!(:queue) { Struct.new(:tabs).new(tabs) }

    include_examples "Standard Queue feature tests"

    scenario "CAMO Queue Loads" do
      expect(find("h1")).to have_content("VHA CAMO cases")
    end

    context "issue types column" do
      scenario "Camo assigned tab displays multiple issue types ordered in ascending order and no duplicates" do
        expect(page).to have_content(
          /\nBeneficiary Travel\nForeign Medical Program\nSpina Bifida Treatment \(Non-Compensation\)\n/
        )
      end
    end
  end
end
