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
        expect(subject).to match(/^000\d{6}$/)
      end
    end
    context "given SSN" do
      let(:ssn) { "123-45-6789" }
      it "returns fake SSN" do
        expect(subject).not_to eq ssn
        expect(subject).to match(/^000-\d{2}-\d{4}$/)
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
    subject { SanitizedJsonExporter.obfuscate_sentence("instructions", sentence) }
    context "given sentence" do
      let(:sentence) { "No PII, just potentially sensitive!" }
      it "returns sentence without any of the original longer words" do
        obf_words = subject.split
        sentence.split.select { |word| word.length > 2 }.each do |word|
          expect(subject).not_to include word
          obf_words.each { |obf_word| expect(obf_word.chars).not_to match_array word.chars }
        end
      end
    end
    context "given empty sentence" do
      let(:sentence) { "" }
      it "returns empty string" do
        expect(subject).to eq ""
      end
    end
  end

  describe "#find_or_create_mapped_value_for" do
    let(:sje) { SanitizedJsonExporter.new(create(:appeal)) }
    subject { sje.send(:find_or_create_mapped_value_for, obj_hash, field_name) }
    context "given input that will cause a loop" do
      let(:field_name) { "my_text" }
      let(:obj_hash) { { field_name => " " } }
      before do
        # Cause a loop to occur by adding an existing value_mapping entry with value ""
        # Both "" and " " (in obj_hash) should both map to "" due to `obfuscate_sentence`
        sje.value_mapping[""] = ""
      end
      it "does not loop indefinitely" do
        expect(SanitizedJsonExporter).to receive(:obfuscate_sentence).and_call_original
        subject
        expect(obj_hash[field_name]).to eq ""
      end
    end

    context "given array as a field value" do
      let(:field_name) { "instructions" }
      let(:obj_hash) { { field_name => ["instruct me", "me too"] } }
      it "sets a new array with new values" do
        expect(SanitizedJsonExporter).to receive(:obfuscate_sentence).and_call_original.exactly(2).times
        subject
        expect(obj_hash[field_name]).to eq ["in me", "me to"]
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
      let(:cavc_remand_users) do
        cavc_remands = relevant_appeals.map(&:cavc_remand).compact
        cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact
      end

      it "includes all associated records" do
        expect(sje.records_hash["appeals"].size).to eq relevant_appeals.size
        expect(sje.records_hash["veterans"].size).to eq veterans.size
        expect(sje.records_hash["claimants"].size).to eq claimants.size

        expect(sje.records_hash["tasks"].size).to eq tasks.size
        expect(sje.records_hash["users"].size).to eq((task_users + cavc_remand_users).uniq.size)
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
    let(:sji) { SanitizedJsonImporter.new(sje.file_contents) }
    subject { sji.import }

    def expect_initial_state
      expect(Appeal.count).to eq 1
      expect(Veteran.count).to eq 1
      expect(Claimant.count).to eq 2
      expect(Organization.count).to eq 2
      expect(User.count).to eq 0
      expect(Task.count).to eq 5
    end

    context "when given empty JSON to import" do
      let(:sji) { SanitizedJsonImporter.new("{}") }
      it "returns nil" do
        expect_initial_state
        expect(subject).to be_nil
        expect_initial_state
      end
    end

    SjDifference = SanitizedJsonDifference

    before do
      sje # causes relevant appeals to be created
    end

    it "creates 1 appeal with associated records" do
      expect_initial_state

      # Cause a new organization to be created instead of using existing same-named org
      sji.records_hash["organizations"].first["id"] = 100

      subject
      record_counts = {
        "appeals" => 1,
        "veterans" => 1,
        "claimants" => 2,
        "users" => 0,
        "organizations" => 2, # only the first org will be created; the second one already exists
        "tasks" => 5,
        "task_timers" => 1,
        "cavc_remands" => 0
      }
      expect(sji.imported_records.transform_values(&:count)).to eq record_counts

      expect(Appeal.count).to eq 2
      expect(Veteran.count).to eq 2
      expect(Claimant.count).to eq 4
      expect(Organization.count).to eq 3
      expect(User.count).to eq 0
      expect(Task.count).to eq 10

      # Compare differences between original records and imported records
      imported_appeal = sji.imported_records["appeals"].first
      appeal_mapped_fields = %w[id veteran_file_number]
      expect(SjDifference.diff_records(appeal, imported_appeal).map(&:first)).to match_array appeal_mapped_fields

      imported_veteran = sji.imported_records["veterans"].first
      veteran_mapped_fields = %w[id file_number first_name middle_name last_name ssn]
      expect(SjDifference.diff_records(veteran, imported_veteran).map(&:first)).to match_array veteran_mapped_fields

      claimant = appeal.claimant
      imported_claimant = sji.imported_records["claimants"].last
      claimant_mapped_fields = %w[id decision_review_id]
      expect(SjDifference.diff_records(claimant, imported_claimant).map(&:first)).to match_array claimant_mapped_fields

      task_mapped_fields = %w[id appeal_id]
      child_task_mapped_fields = task_mapped_fields + %w[parent_id]
      appeal.tasks.order(:id).zip(imported_appeal.tasks.order(:id)).each do |task, imported_task|
        if task.parent
          expect(SjDifference.diff_records(task, imported_task).map(&:first)).to match_array child_task_mapped_fields
        else
          expect(SjDifference.diff_records(task, imported_task).map(&:first)).to match_array task_mapped_fields
        end
      end

      # check imported claimant and task is correctly reassociated with imported_appeal
      expect(imported_claimant.decision_review).to eq imported_appeal
      expect(sji.imported_records["tasks"].map(&:appeal).uniq).to eq [imported_appeal]
    end

    context "when exporting CAVC remand appeal" do
      let!(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
      let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
      let(:window_task) do
        send_task = cavc_appeal.tasks.open.where(type: :SendCavcRemandProcessedLetterTask).last
        child_send_task = create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin)
        child_send_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin)

        cavc_appeal.tasks.where(type: CavcRemandProcessedLetterResponseWindowTask.name).first
      end

      let(:sje) do
        # simulates "Assign to person", which creates child task
        CavcRemandProcessedLetterResponseWindowTask.create!(parent: window_task,
                                                            appeal: window_task.appeal,
                                                            assigned_to: org_nonadmin)
        SanitizedJsonExporter.new(cavc_appeal)
      end

      it "creates CAVC and source appeal with associated records" do
        expect(Appeal.count).to eq 2
        expect(Veteran.count).to eq 1
        expect(Claimant.count).to eq 2
        expect(Organization.count).to eq 8
        expect(User.count).to eq 7
        expect(Task.count).to eq 16
        expect(TaskTimer.count).to eq 2

        subject
        record_counts = {
          "appeals" => 2,
          "veterans" => 1,
          "claimants" => 2,
          "users" => 6,
          "organizations" => 4,
          "tasks" => 16,
          "task_timers" => 2,
          "cavc_remands" => 1
        }
        expect(sji.imported_records.transform_values(&:count)).to eq record_counts

        expect(Appeal.count).to eq 4
        expect(Veteran.count).to eq 2
        expect(Claimant.count).to eq 4
        expect(Organization.count).to eq 8 # existing orgs are reused
        expect(User.count).to eq 13
        expect(Task.count).to eq 32
        expect(TaskTimer.count).to eq 4

        # Check users and orgs associated with tasks exists
        imported_appeals = sji.imported_records["appeals"]
        imported_appeals.map(&:tasks).flatten.each do |task|
          expect(task.assigned_by).not_to be_nil if task.assigned_by_id
          expect(task.assigned_to).not_to be_nil if task.assigned_to_id
        end

        orig_appeals = [cavc_appeal, cavc_source_appeal]
        orig_users = User.where(id: sje.records_hash["users"].pluck("id")).order(:id)

        # pp sji.differences(orig_appeals, orig_users, ignore_expected_diffs: false)
        pp sje.records_hash.transform_values(&:count)
        pp sji.differences(orig_appeals, orig_users, ignore_expected_diffs: false).transform_values(&:count)
        # binding.pry

        not_imported_counts = sje.records_hash.transform_values(&:count).to_a -
                              sji.imported_records.transform_values(&:count).to_a
        expect(not_imported_counts).to eq [["metadata", 1]]

        diffs = sji.differences(orig_appeals, orig_users)
        expect(diffs.values.flatten).to be_empty
      end
    end
  end
end
