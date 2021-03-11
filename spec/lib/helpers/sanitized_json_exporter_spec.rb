# frozen_string_literal: true

require "helpers/sanitized_json_exporter.rb"
require "helpers/sanitized_json_importer.rb"

describe "SanitizedJsonExporter/Importer" do
  describe ".invalid_ssn" do
    subject { SanitizedJsonExporter.invalid_ssn(nil, ssn) }
    context "given 9-digit number" do
      let(:ssn) { "123456789" }
      it "returns fake SSN" do
        expect(subject).not_to eq ssn
        expect(subject).to match(/^\d{9}$/)
      end
    end
    context "given SSN" do
      let(:ssn) { "123-45-6789" }
      it "returns fake SSN" do
        expect(subject).not_to eq ssn
        expect(subject).to match(/^\d{3}-\d{2}-\d{4}$/)
      end
    end
  end

  describe ".random_email" do
    let(:orig_value) { "yoom@caseflow.va.gov" }
    let(:field_prefix) { ["", ("a".."z").to_a.sample(rand(9)).join].sample }
    subject { SanitizedJsonExporter.random_email(field_name, orig_value) }
    context "given fieldname ending with 'email'" do
      let(:field_name) { "#{field_prefix}email" }
      it "returns fake email" do
        expect(subject).not_to eq orig_value
        expect(subject.length).to be > 0
      end
    end
    context "given email value" do
      let(:field_name) { nil }
      it "returns fake email" do
        expect(subject).not_to eq orig_value
        expect(subject.length).to be > 0
      end
    end
  end

  describe ".random_person_name" do
    let(:orig_value) { "Yoom" }
    let(:field_prefix) { ["full", "first", "last", "middle", ("a".."z").to_a.sample(rand(9)).join].sample }
    subject { SanitizedJsonExporter.random_person_name("#{field_prefix}_name", orig_value) }
    context "given fieldname ending with _name" do
      it "returns fake name" do
        expect(subject).not_to eq orig_value
        expect(subject.length).to be > 0
      end
    end
  end

  describe ".mixup_css_id" do
    subject { SanitizedJsonExporter.mixup_css_id("css_id", css_id) }
    context "given CSS_ID" do
      let(:css_id) { create(:intake_user).css_id }
      it "returns mixed-up CSS_ID" do
        expect(subject).not_to eq css_id
        expect(subject.chars.sort).to eq css_id.chars.sort
      end
    end
  end

  describe ".obfuscate_sentence" do
    subject { SanitizedJsonExporter.obfuscate_sentence(nil, sentence) }
    context "given CSS_ID" do
      let(:sentence) { "No PII, just potentially sensitive!" }
      it "returns sentence without any of the original longer words" do
        obf_words = subject.split
        sentence.split.select { |word| word.length > 2 }.each do |word|
          expect(subject).not_to include word
          obf_words.each { |obf_word| expect(obf_word.chars).not_to match_array word.chars }
        end
      end
    end
  end

  let(:veteran) { create(:veteran, file_number: "111447777", middle_name: "Middle") }
  let(:appeal) do
    create(:appeal,
           :advanced_on_docket_due_to_motion,
           :with_schedule_hearing_tasks,
           :with_post_intake_tasks,
           veteran: veteran)
  end
  let(:sje) { SanitizedJsonExporter.new(appeal) }

  let(:cavc_appeal) do
    create(:appeal,
           :type_cavc_remand,
           veteran: veteran).tap do |_appeal|
             User.all.each { |user| user.update(email: "sensitive#{rand(9)}@va.gov") }
           end
  end
  let(:cavc_source_appeal) do
    cavc_appeal.cavc_remand.source_appeal
  end

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

  context "Exporter" do
    shared_examples "exports appeals" do
      let(:relevant_appeals) { (appeals + [cavc_source_appeal]).uniq }
      let(:claimants) { relevant_appeals.map(&:claimants).flatten.uniq }
      let(:veterans) { relevant_appeals.map(&:veteran).uniq }
      let(:tasks) { relevant_appeals.map(&:tasks).flatten }
      let(:assigned_by_users) { tasks.map(&:assigned_by).uniq.compact }
      let(:assigned_to_users) { tasks.select { |task| task.assigned_to_type == "User" }.map(&:assigned_to).uniq }
      let(:assigned_to_orgs) { tasks.select { |task| task.assigned_to_type == "Organization" }.map(&:assigned_to).uniq }
      let(:task_users) { (assigned_by_users + assigned_to_users).uniq }

      it "includes all associated records" do
        expect(sje.records_hash["appeals"].size).to eq relevant_appeals.size
        expect(sje.records_hash["veterans"].size).to eq veterans.size
        expect(sje.records_hash["claimants"].size).to eq claimants.size

        expect(sje.records_hash["tasks"].size).to eq tasks.size
        expect(sje.records_hash["users"].size).to eq task_users.size
        expect(sje.records_hash["organizations"].size).to eq assigned_to_orgs.size

        # Check associations
        relevant_appeal_ids = relevant_appeals.pluck(:id)
        expect(sje.records_hash["claimants"].pluck("decision_review_id").uniq).to match_array relevant_appeal_ids
        expect(sje.records_hash["tasks"].pluck("appeal_id").uniq).to match_array tasks.pluck(:appeal_id).uniq
        sanitized_vet_file_numbers = sje.records_hash["veterans"].pluck("file_number").uniq
        expect(sje.records_hash["appeals"].pluck("veteran_file_number").uniq).to match_array sanitized_vet_file_numbers

        # To-do: Issues
        # To-do: Hearings
      end
    end

    let(:pii_values) do
      (task_users.pluck(:full_name, :email, :css_id).flatten +
        [
          appeal.veteran_file_number,
          appeal.veteran.file_number,
          appeal.veteran.first_name,
          appeal.veteran.last_name,
          appeal.veteran.ssn
        ]).uniq
    end

    context "when sanitize=false (for debugging)" do
      let(:appeals) { [appeal, cavc_appeal, create(:appeal)] }
      let(:sje) { SanitizedJsonExporter.new(*appeals, sanitize: false) }

      include_examples "exports appeals"

      it "includes PII in file_contents" do
        # Check PII values are in file_contents
        expect(sje.file_contents).to include(*pii_values)
        # No values are mapped
        expect(sje.value_mapping).to be_empty
      end
    end

    context "when exporting normally" do
      let(:appeals) { [appeal, cavc_appeal, create(:appeal)] }
      let(:sje) { SanitizedJsonExporter.new(*appeals) }

      include_examples "exports appeals"

      it "does not include PII in file_contents" do
        # Check PII values will be mapped to fake values
        expect(sje.value_mapping.keys).to include(*pii_values)
        expect(sje.value_mapping.values).not_to include(*pii_values)

        # Check PII values are in file_contents
        expect(sje.file_contents).not_to include(*pii_values)
        # Check file_contents uses fake values instead of PII values
        expect(sje.file_contents).to include(*sje.value_mapping.values)
      end
    end
  end

  context "Importer" do
    subject { sji.import }
    context "when given empty JSON to import" do
      let(:sji) { SanitizedJsonImporter.new("{}") }
      it "returns nil" do
        expect(subject).to be_nil
        expect(Appeal.count).to eq 0
        expect(Veteran.count).to eq 0
        expect(Claimant.count).to eq 0
        expect(User.count).to eq 0
        expect(Task.count).to eq 0
      end
    end

    let!(:sji) { SanitizedJsonImporter.new(sje.file_contents) }

    # for debugging
    def show_diffs(appeal, record_hash, imp_appeal)
      orig_appeal_hash = SanitizedJsonExporter.record_to_hash(appeal)
      imported_appeal_hash = SanitizedJsonExporter.record_to_hash(imp_appeal)

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

      # Cause a new organization to be created instead of using existing same-named org
      sji.records_hash["organizations"].first["id"] = 100

      appeals = subject["appeals"]
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

    context "when exporting CAVC remand appeal" do
      let(:sje) { SanitizedJsonExporter.new(cavc_appeal) }

      it "imports CAVC and source appeal" do
        # print_things

        subject
        expect(sji.imported_records["appeals"].size).to eq 2
        # binding.pry
        # sji.import
        # print_imported_things
      end
    end
  end
end
