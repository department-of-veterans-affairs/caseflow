# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "CaseMovementTeam task actions" do
  # Ticket https://github.com/department-of-veterans-affairs/caseflow/issues/16205#
  # https://github.com/department-of-veterans-affairs/dsva-vacols/issues/187
  # Target state: TBD -- see tcket
  describe "during Quality Review" do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/scm-cant-reassign.json", verbosity: 5)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    it "produces error and user can't reassign to attorney" do
      # To replicate error:
      # binding.pry # Uncomment this line then do the following manually
      # Clicking on "Assign to attorney" shows the "Assign task" modal. 
      # Clicking on "Select a user" shows "Other". 
      # Clicking on "Other" and starting to type "TALAM" shows the attorney. 
      # Clicking Submit button shows an "Error assigning tasks" error banner in the modal 
      # (and an error message in the DevTools console).
    end
  end
end
