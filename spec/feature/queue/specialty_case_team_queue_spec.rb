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

    let!(:sct_action_required_task) do
      create_list(:sct_assign_task, num_action_required_rows, :on_hold, assigned_to: sct_org)
    end

    let!(:sct_completed_tasks) do
      create_list(:sct_assign_task, num_completed_rows, :completed, assigned_to: sct_org)
    end

    before do
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

    scenario "Specialty Case Team Queue Loads" do
      expect(find("h1")).to have_content("Specialty Case Team cases")
    end

    scenario "issue types column" do
      # scenario "SCT action required tab displays multiple issue types ordered in ascending order and no duplicates" do

      # end
      expect(page).to have_content("Caregiver | Other ")
    end
  end
end
