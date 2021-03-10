# frozen_string_literal: true

require "helpers/sanitized_json_exporter.rb"
require "helpers/sanitized_json_importer.rb"

describe "SanitizedJsonExporter/Importer" do
  let(:veteran) { create(:veteran, file_number: "111447777") }
  let(:appeal) do
    create(:appeal,
           :advanced_on_docket_due_to_motion,
           :with_schedule_hearing_tasks,
           :with_post_intake_tasks,
           veteran: veteran)
  end
  let(:sje) { SanitizedJsonExporter.new(appeal) }

  # temporary method for debugging
  def print_things
    pp appeal
    appeal.treee
    pp appeal.veteran
    pp appeal.claimants
    pp appeal.issues

    pp sje.value_mapping
    pp sje.records_hash
  end

  context "export" do
    let(:pii_values) do
      [
        appeal.veteran_file_number,
        appeal.veteran.first_name,
        appeal.veteran.last_name,
        appeal.veteran.ssn
      ]
    end
      
    it "exports appeal" do
        # Check PII values will be mapped to fake values
      expect(sje.value_mapping.keys).to include(*pii_values)
      expect(sje.value_mapping.values).not_to include(*pii_values)

      expect(sje.records_hash["claimants"].size).to eq appeal.claimants.size
      expect(sje.records_hash["tasks"].size).to eq appeal.tasks.size

      expect(sje.records_hash["claimants"].size).to eq appeal.claimants.size

      # Check PII values are not in file_contents
      expect(sje.file_contents).not_to include(*pii_values)
      # Check file_contents uses fake values
      expect(sje.file_contents).to include(*sje.value_mapping.values)

      # After import, Check associations
      expect(sje.records_hash["claimants"].first["decision_review_id"]).to eq appeal.id
    end
  end

  context "import" do
    let(:sji) { SanitizedJsonImporter.new(sje.file_contents) }

    before { sji.metadata }

    # for debugging
    def show_diffs(appeal, record_hash, imp_appeal)
      orig_appeal_hash = SanitizedJsonExporter.to_hash(appeal)
      imported_appeal_hash = SanitizedJsonExporter.to_hash(imp_appeal)

      pp "======== show_diffs: orig_appeal_hash, imported_appeal_hash,   ignore_id_offset: false"
      pp SanitizedJsonImporter.diff_hashes(orig_appeal_hash, imported_appeal_hash, ignore_id_offset: false)
      pp "-------- show_diffs: orig_appeal_hash, imported_appeal_hash"
      pp SanitizedJsonImporter.diff_hashes(orig_appeal_hash, imported_appeal_hash)

      pp "-------- show_diffs: record_hash, imported_appeal_hash,   convert_timestamps: false"
      pp SanitizedJsonImporter.diff_hashes(record_hash, imported_appeal_hash, convert_timestamps: false)
      pp "-------- show_diffs: record_hash, imported_appeal_hash"
      pp SanitizedJsonImporter.diff_hashes(record_hash, imported_appeal_hash)
      # binding.pry
    end

    # temporary method for debugging
    def print_imported_things
      imp_appeal = sji.imported_records["appeals"].first
      imp_veteran = sji.imported_records[Veteran.name]
      imp_claimant = sji.imported_records[Claimant.name]

      pp imp_appeal
      imp_appeal.treee
      pp imp_veteran
      pp imp_claimant

      show_diffs(appeal, sji.records_hash["appeals"].first, imp_appeal)
    end

    it "imports json" do
      expect(Appeal.count).to eq 1
      expect(Veteran.count).to eq 1
      expect(Claimant.count).to eq 2
      expect(User.count).to eq 0

      appeals = sji.import["appeals"]
      expect(appeals.size).to eq 1

      expect(Appeal.count).to eq 2
      expect(Veteran.count).to eq 2
      expect(Claimant.count).to eq 4
      expect(User.count).to eq 0

      # TODO: diff other record types
      imp_appeal = sji.imported_records["appeals"].first
      expect(SanitizedJsonImporter.diff_records(appeal, imp_appeal, ignore_id_offset: false)).not_to be_empty
      expect(SanitizedJsonImporter.diff_records(appeal, imp_appeal).map(&:first)).to include "veteran_file_number"

      # Not necessarily true: expect(imp_veteran.participant_id).to eq imp_claimant.participant_id
      imp_claimant = sji.imported_records["claimants"].last
      expect(imp_claimant.decision_review).to eq imp_appeal
    end

    context "when appeal has task assigned to users" do
      let(:cavc_appeal) do
        create(:appeal,
               :type_cavc_remand,
               veteran: veteran)
      end
      let(:appeal) do
        cavc_appeal.cavc_remand.source_appeal
      end

      it "imports json" do
        # print_things

        sji.import
        # print_imported_things
      end
    end
  end
end
