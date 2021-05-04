# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "CaseMovementTeam can't reassign to attorney" do
  # https://github.com/department-of-veterans-affairs/dsva-vacols/issues/187
  # Target state: 
  # - 
  describe "..." do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/scm-cant-reassign.json", verbosity: 5)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    it "restores decision_document and fixes task tree" do
      appeal.reload.treee

      binding.pry
      appeal.reload.treee
    end
  end
end
