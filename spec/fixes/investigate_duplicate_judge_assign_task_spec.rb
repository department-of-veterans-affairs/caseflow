# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

# required to load `explain` endpoint in an RSpec
require "helpers/sanitized_json_exporter.rb"
require "helpers/intake_renderer.rb"
require "helpers/hearing_renderer.rb"

feature "duplicate JudgeAssignTask investigation" do
  before do
    User.authenticate!(css_id: "PETERSBVAM")
    Functions.grant!("System Admin", users: ["PETERSBVAM"]) # enable access to `export` endpoint
  end

  # Ticket: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/174
  # Target state: should only have 1 open JudgeAssignTask
  describe "Judge cancels AttorneyTask in 2 browser windows" do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/appeal-121304-dup_jatasks.json", verbosity: 0)
      sji.import
      appeal = sji.imported_records[Appeal.table_name].first

      judge = User.find_by_css_id("PETERSBVAM")
      create(:staff, :judge_role, user: judge)

      appeal.reload
    end

    scenario "Caseflow creates 2 open JudgeAssignTasks" do
      within_window open_new_window do
        # Get a narrative of what happened; search for ":50:38" and ":50:44"
        visit "/explain/appeals/#{appeal.uuid}"
        expect(page).to have_content("Narrative Table")
        page.find("#narrative_table_chkbox + label").click
        expect(page).to have_content("50:38")
        expect(page).to have_content("JudgeAssignTask_2001775444")
        expect(page).to have_content("50:44")
        expect(page).to have_content("JudgeAssignTask_2001775445")
      end

      # Delete tasks created on or after 2021-06-13 so we can recreate the problem
      appeal.tasks.where("created_at >= ?", "2021-06-13").delete_all
      # Set task status so that user as task actions
      Task.find(2_001_437_274).assigned!
      Task.find(2_001_437_273).on_hold!

      # In first window
      visit "/queue/appeals/#{appeal.uuid}"

      # Open another window to the same page
      second_window = open_new_window
      within_window second_window do
        visit "/queue/appeals/#{appeal.uuid}"
      end

      # Back in first window
      click_dropdown(prompt: "Select an action", text: "Cancel task and return to judge")
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "cancel once")
      click_on "Submit"
      expect(page).to have_content("case has been cancelled")

      # Attempt to repeat same actions in second_window.
      # Should fail due to limit on number of open tasks of type JudgeAssignTask.
      within_window second_window do
        click_dropdown(prompt: "Select an action", text: "Cancel task and return to judge")
        fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "cancel once")
        click_on "Submit"
        expect(page).to have_content("Error assigning tasks")
        expect(page).to have_content("Looks like this appeal already has an open JudgeAssignTask")
      end
    end
  end
end
