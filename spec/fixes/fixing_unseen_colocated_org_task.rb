# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

feature "Missing org task in Case Details" do
  before do
    User.authenticate!(css_id: "VLJ_SUPPORT_ADMIN") # SANFORDBVAM
  end

  # let(:attorney_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Talam") }
  # let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }

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
    before { ihp_org_task.update!(assigned_to: Colocated.singleton) }

    scenario "produces error and user can't reassign to attorney" do
      expect(ihp_org_task.status).to eq "assigned"
      expect(ihp_user_ask.status).to eq "cancelled"

      visit "/queue/appeals/#{appeal.uuid}"

      # click_dropdown(prompt: "Select an action", text: "Assign to attorney")

      # Clicking on "Select a user" shows "Other".
      # click_dropdown(prompt: "Select a user", text: "Other")

      # Clicking on "Other" and starting to type "TALAM" shows the attorney.
      # click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
      # fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "\nSCM user reassigning to different attorney")

      # Clicking Submit button shows an "Error assigning tasks" error banner in the modal
      # (and an error message in the DevTools console).
      # click_on "Submit"
      # expect(page).to have_content("Error assigning tasks")
    end
  end
end
