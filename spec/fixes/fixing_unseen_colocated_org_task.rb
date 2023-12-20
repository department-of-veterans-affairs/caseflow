# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

feature "Missing org task in Case Details" do
  # Relates to CASEFLOW-1125 and CASEFLOW-1549
  # Ticket https://github.com/department-of-veterans-affairs/dsva-vacols/issues/228
  # Problem: Case Details does not show org tasks in the "Currently active tasks" section if they had child user tasks
  #   of the same type, regardless of the status of the child task(s)
  # AC: Org tasks w/ status assigned can be assigned to a user in Case Details page
  describe "during JudgeDecisionReviewTask" do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/appeal-188663.json", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end
    let(:ihp_org_task) { appeal.tasks.open.assigned_to_any_org.find_by(type: :IhpColocatedTask) }
    let(:ihp_user_ask) { ihp_org_task.children.first }
    let(:admin_user) { User.find_by_css_id("SANFORDBVAM") }
    before do
      expect(ihp_org_task.status).to eq "assigned"
      expect(ihp_user_ask.status).to eq "cancelled"

      ihp_org_task.update!(assigned_to: Colocated.singleton)
      User.authenticate!(user: admin_user)
    end

    scenario "admin_user has task actions to select" do
      visit "/queue/appeals/#{appeal.uuid}"

      click_dropdown(prompt: "Select an action", text: "Assign to person")
      click_on "Submit"
      expect(page).to have_content("Task assigned to")
    end
  end
end
