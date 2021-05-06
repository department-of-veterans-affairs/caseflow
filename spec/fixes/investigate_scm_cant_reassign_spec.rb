# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

feature "CaseMovementTeam task actions" do
  before do
    User.authenticate!(css_id: "SANFORDBVAM")
  end

  let(:attorney_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Talam") }
  let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }

  # Ticket https://github.com/department-of-veterans-affairs/caseflow/issues/16205#
  # https://github.com/department-of-veterans-affairs/dsva-vacols/issues/187
  # Target state: TBD -- see tcket
  describe "during Quality Review" do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/scm-cant-reassign.json", verbosity: 5)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    scenario "produces error and user can't reassign to attorney" do
      visit "/queue/appeals/#{appeal.uuid}"

      # Clicking on "Assign to attorney" shows the "Assign task" modal.
      click_dropdown(prompt: "Select an action", text: "Assign to attorney")

      # Clicking on "Select a user" shows "Other".
      click_dropdown(prompt: "Select a user", text: "Other")

      # Clicking on "Other" and starting to type "TALAM" shows the attorney.
      click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "\nSCM user reassigning to different attorney")

      # Clicking Submit button shows an "Error assigning tasks" error banner in the modal
      # (and an error message in the DevTools console).
      click_on "Submit"
      expect(page).to have_content("Error assigning tasks")
      # binding.pry # Uncomment this line to see error message
    end
  end
end
