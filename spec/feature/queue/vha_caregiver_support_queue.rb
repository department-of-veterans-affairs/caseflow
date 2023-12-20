# frozen_string_literal: true

require_relative "./queue_shared_examples_spec.rb"

feature "VhaCaregiverSupportQueue", :all_dbs do
  context "Load Caregiver Support Queue" do
    let(:csp_org) { VhaCaregiverSupport.singleton }
    let(:csp_user) { User.authenticate!(roles: ["CAREGIVERADMIN"]) }
    let(:unassigned_tab_text) { "Unassigned" }
    let(:in_progress_tab_text) { "In Progress" }
    let(:completed_tab_text) { "Completed" }
    let(:column_heading_names) do
      [
        "Case Details", "Issue Type", "Tasks", "Assigned By", "Types", "Docket", "Days Waiting", "Veteran Documents"
      ]
    end
    let!(:num_unassigned_rows) { 3 }
    let!(:num_in_progress_rows) { 9 }
    let!(:num_completed_rows) { 5 }

    let!(:vha_caregiver_unassigned_tasks) do
      create_list(:vha_document_search_task, num_unassigned_rows, :assigned, assigned_to: csp_org)
    end
    let!(:vha_caregiver_in_progress_tasks) do
      create_list(:vha_document_search_task, num_in_progress_rows, :in_progress, assigned_to: csp_org)
    end
    let!(:vha_caregiver_completed_tasks) do
      create_list(:vha_document_search_task, num_completed_rows, :completed, assigned_to: csp_org)
    end

    before do
      csp_org.add_user(csp_user)
      csp_user.reload
      visit "/organizations/#{csp_org.url}"
    end

    # Setup variables for the Standard Queue feature tests shared examples
    let!(:tabs) do
      test_tab = Struct.new(:tab_name, :tab_columns, :tab_body_text, :number_of_tasks)
      [
        test_tab.new(unassigned_tab_text, column_heading_names, "Cases assigned to VHA Caregiver Support Program:",
                     num_unassigned_rows),
        test_tab.new(in_progress_tab_text, column_heading_names, "Cases assigned to VHA Caregiver Support Program:",
                     num_in_progress_rows),
        test_tab.new(completed_tab_text, column_heading_names, "Cases completed (last 7 days):", num_completed_rows)
      ]
    end
    let!(:queue) { Struct.new(:tabs).new(tabs) }

    include_examples "Standard Queue feature tests"

    scenario "Caregiver Support Queue Loads" do
      expect(find("h1")).to have_content("VHA Caregiver Support Program cases")
    end

    context "issue types column" do
      let!(:assigned_request_issues) do
        [
          create(:request_issue, :nonrating,
                 decision_review: vha_caregiver_unassigned_tasks.first.appeal,
                 nonrating_issue_category: "Eligibility for Dental Treatment", benefit_type: "vha"),
          create(:request_issue, :nonrating,
                 decision_review: vha_caregiver_unassigned_tasks.first.appeal,
                 nonrating_issue_category: "Caregiver | Other", benefit_type: "vha"),
          create(:request_issue, :nonrating,
                 decision_review: vha_caregiver_unassigned_tasks.first.appeal,
                 nonrating_issue_category: "Caregiver | Other", benefit_type: "vha"),
          create(:request_issue, :nonrating,
                 decision_review: vha_caregiver_unassigned_tasks.first.appeal,
                 nonrating_issue_category: "Foreign Medical Program", benefit_type: "vha")
        ]
      end

      scenario "Camo assigned tab displays multiple issue types ordered in ascending order and no duplicates" do
        expect(page).to have_content(
          /\nCaregiver | Other\nEligibility for Dental Treatment\nForeign Medical Program\n/
        )
      end
    end
  end
end
