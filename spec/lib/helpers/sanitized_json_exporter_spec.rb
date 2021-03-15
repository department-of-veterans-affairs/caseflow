# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_exporter.rb"
require "helpers/sanitized_json_importer.rb"

describe "SanitizedJsonExporter/Importer" do
  SjConfiguration = SanitizedJsonConfiguration

  describe ".invalid_ssn" do
    subject { SjConfiguration.new.invalid_ssn(nil, ssn) }
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

  describe ".random_pin" do
    let(:obj_class) { nil }
    subject { SjConfiguration.new.random_pin(field_name, orig_value, obj_class: obj_class) }
    let(:field_name) { "guest_pin" }
    context "given fieldname ending with 'pin' and string value" do
      let(:orig_value) { "12345" }
      it "returns fake PIN string" do
        expect(subject).not_to eq orig_value
        expect(subject.is_a?(String)).to be true
        expect(subject).to match(/^\d*$/)
        expect(subject.to_s.length).to eq orig_value.to_s.length
      end
    end
    context "given fieldname ending with 'pin' and number value" do
      let(:orig_value) { 1234 }
      it "returns fake PIN integer" do
        expect(subject).not_to eq orig_value
        expect(subject.is_a?(Integer)).to be true
        expect(subject.to_s.length).to eq orig_value.to_s.length
      end
    end
    context "given VirtualHearing's fieldname 'alias' and String value" do
      let(:obj_class) { VirtualHearing }
      let(:field_name) { "alias" }
      let(:orig_value) { "0007483" }
      it "returns fake alias string" do
        expect(subject).not_to eq orig_value
        expect(subject.is_a?(String)).to be true
        expect(subject).to match(/^\d*$/)
        expect(subject.to_s.length).to eq orig_value.to_s.length
      end
    end
  end

  describe ".random_email" do
    let(:orig_value) { "yoom@caseflow.va.gov" }
    let(:field_prefix) { ["", ("a".."z").to_a.sample(rand(9)).join].sample }
    subject { SjConfiguration.new.random_email(field_name, orig_value) }
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
    let(:field_name) { "#{field_prefix}_name" }
    subject { SjConfiguration.new.random_person_name(field_name, orig_value) }
    context "given fieldname ending with _name" do
      it "returns fake name" do
        expect(subject).not_to eq orig_value
        expect(subject.length).to be > 0
      end
    end
    context "given witness" do
      let(:orig_value) { "Elena Smith (daughter)" }
      let(:field_name) { "witness" }
      it "returns witness list as a string" do
        expect(subject).not_to eq orig_value
        expect(subject).to match(/^.* \(.*\)$/)
      end
    end
  end

  describe ".similar_date" do
    subject { SjConfiguration.new.similar_date("date_of_birth", orig_value) }
    context "given date_of_birth as Date" do
      let(:orig_value) { Date.parse("1938-09-05") }
      it "returns random Date in the last year prior to orig_value" do
        expect(subject).not_to eq orig_value
        expect(subject.is_a?(Date)).to be true
        expect(subject).to be_within(1.year).of(orig_value)
      end
    end
    context "given date_of_birth as string" do
      let(:orig_value) { "1938-09-05" }
      it "returns random date string in the last year prior to orig_value" do
        expect(subject).not_to eq orig_value
        expect(subject.is_a?(String)).to be true
        expect(Date.parse(subject)).to be_within(1.year).of(Date.parse(orig_value))
      end
    end
  end

  describe ".mixup_css_id" do
    subject { SjConfiguration.new.mixup_css_id("css_id", css_id) }
    context "given CSS_ID" do
      let(:css_id) { create(:intake_user).css_id }
      it "returns mixed-up CSS_ID" do
        expect(subject).not_to eq css_id
        expect(subject.chars.sort).to eq css_id.chars.sort
      end
    end
  end

  describe ".obfuscate_sentence" do
    let(:field_name) { "instructions" }
    subject { SjConfiguration.new.obfuscate_sentence(field_name, sentence) }
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
    context "given military_service field" do
      let(:field_name) { "military_service" }
      let(:sentence) { "ARMY 09/09/1993 - 06/12/1996, Honorable" }
      it "returns fake military_service" do
        expect(subject).not_to eq sentence
        expect(subject).to match(/.* - .*,/)
      end
    end
    context "given summary field" do
      let(:field_name) { "summary" }
      let(:sentence) { "<p><strong>Contentions</strong>&nbsp;</p> blah <p><strong>Evidence</strong>&nbsp;</p> ..." }
      it "returns fake summary" do
        expect(subject).not_to eq sentence
        expect(subject).to match(/.*Contentions.*/)
      end
    end
  end

  describe "AssocationWrapper#untyped_associations_with User records" do
    subject { AssocationWrapper.new(target_class).untyped_associations_with(User).fieldnames }
    context "for Task class" do
      let(:target_class) { Task }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[assigned_by_id cancelled_by_id]
      end
    end
    context "for Hearing class" do
      let(:target_class) { Hearing }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[created_by_id judge_id updated_by_id]
      end
    end
    context "for AppealIntake class" do
      let(:target_class) { AppealIntake }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[user_id]
      end
    end

    context "SjConfiguration uses of AssocationWrapper" do
      let(:configuration) { SjConfiguration.new }
      it "causes SjConfiguration instances to return correct results" do
        expect(configuration.transform_methods).to include(:random_pin, :obfuscate_sentence, :similar_date)
        expect(configuration.transform_methods).not_to include(:to_s, :to_i, :instance_methods)

        offset_id_fields = {
          DecisionReview => [],
          # Veteran => [],
          AppealIntake => [],
          JudgeCaseReview => ["task_id"],
          AttorneyCaseReview => ["task_id"],
          DecisionDocument => [],
          Claimant => ["decision_review_id"],
          Task => %w[parent_id],
          TaskTimer => ["task_id"],
          CavcRemand => %w[decision_issue_ids],
          DecisionIssue => ["decision_review_id"],
          RequestIssue => %w[contested_decision_issue_id
                             corrected_by_request_issue_id
                             decision_review_id
                             ineligible_due_to_id],
          RequestDecisionIssue => %w[decision_issue_id request_issue_id],
          Hearing => %w[hearing_day_id],
          HearingTaskAssociation => %w[hearing_id hearing_task_id],
          HearingDay => [],
          VirtualHearing => ["hearing_id"],
          OrganizationsUser => []
        }
        # pp configuration.offset_id_fields.transform_keys(&:name)
        expect(configuration.offset_id_fields).to eq offset_id_fields

        reassociate_fields_keys = [:type, "Appeal", "Veteran", "Person", "User", "Organization"]
        expect(configuration.reassociate_fields.keys).to match_array reassociate_fields_keys

        reassociate_fields_for_polymorphics = {
          Task => %w[assigned_to_id appeal_id],
          AppealIntake => ["detail_id"],
          DecisionDocument => ["appeal_id"]
        }
        expect(configuration.reassociate_fields[:type]).to eq(reassociate_fields_for_polymorphics)

        reassociate_fields_for_appeal = {
          CavcRemand => %w[source_appeal_id remand_appeal_id],
          Hearing => ["appeal_id"]
        }
        expect(configuration.reassociate_fields["Appeal"]).to eq(reassociate_fields_for_appeal)

        reassociate_fields_for_user = {
          AppealIntake => ["user_id"],
          JudgeCaseReview => %w[judge_id attorney_id],
          AttorneyCaseReview => %w[reviewing_judge_id attorney_id],
          Task => %w[assigned_by_id cancelled_by_id],
          CavcRemand => %w[updated_by_id created_by_id],
          Hearing => %w[updated_by_id judge_id created_by_id],
          HearingDay => %w[updated_by_id judge_id created_by_id],
          VirtualHearing => %w[updated_by_id created_by_id],
          OrganizationsUser => ["user_id"]
        }
        expect(configuration.reassociate_fields["User"]).to eq(reassociate_fields_for_user)
      end
    end
  end

  describe "#find_or_create_mapped_value_for" do
    let(:sje) { SanitizedJsonExporter.new(create(:appeal)) }
    subject { sje.send(:find_or_create_mapped_value_for, obj_hash, field_name) }

    context "given array as a field value" do
      let(:field_name) { "instructions" }
      let(:obj_hash) { { field_name => ["instruct me", "me too"] } }
      it "sets a new array with new values" do
        expect(sje.instance_variable_get("@configuration")).to receive(:obfuscate_sentence)
          .and_call_original.at_least(:once)
        subject
        expect(obj_hash[field_name]).to eq ["in me", "me to"]
      end
    end
  end

  describe "#default_mapped_value" do
    let(:sje) { SanitizedJsonExporter.new(nil) }
    subject { sje.send(:default_mapped_value, orig_value, "some_field") }

    context "given an integer" do
      let(:orig_value) { 12 }
      it "returns 0" do
        expect { subject }.to output(/WARNING: Don't know how to map value/).to_stdout
        expect(subject).to eq 0
      end
    end
    context "given a string" do
      let(:orig_value) { "blah" }
      it "returns empty string" do
        expect { subject }.to output(/WARNING: Don't know how to map value/).to_stdout
        expect(subject).to eq ""
      end
    end
    context "given an array" do
      let(:orig_value) { ["blah", 123] }
      it "returns empty array" do
        expect { subject }.to output(/WARNING: Don't know how to map value/).to_stdout
        expect(subject).to eq []
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
    let(:field_name) { "instructions" }
    subject { SanitizedJsonExporter.obfuscate_sentence(field_name, sentence) }
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
    context "given military_service field" do
      let(:field_name) { "military_service" }
      let(:sentence) { "ARMY 09/09/1993 - 06/12/1996, Honorable" }
      it "returns fake military_service" do
        expect(subject).not_to eq sentence
        expect(subject).to match(/.* - .*,/)
      end
    end
    context "given summary field" do
      let(:field_name) { "summary" }
      let(:sentence) { "<p><strong>Contentions</strong>&nbsp;</p> blah <p><strong>Evidence</strong>&nbsp;</p> ..." }
      it "returns fake summary" do
        expect(subject).not_to eq sentence
        expect(subject).to match(/.*Contentions.*/)
      end
    end
  end

  describe ".fieldnames_of_untyped_associations_with User records" do
    subject { SanitizedJsonExporter.fieldnames_of_untyped_associations_with(User, target_class) }
    context "for Task class" do
      let(:target_class) { Task }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[assigned_by_id cancelled_by_id]
      end
    end
    context "for Hearing class" do
      let(:target_class) { Hearing }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[created_by_id judge_id updated_by_id]
      end
    end
    context "for AppealIntake class" do
      let(:target_class) { AppealIntake }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[user_id]
      end
    end

    it "temporary" do
      # pp SanitizedJsonExporter::OFFSET_ID_FIELDS.transform_keys(&:name)
      offset_id_fields = {
        DecisionReview => [],
        AppealIntake => [],
        Veteran => [],
        Claimant => ["decision_review_id"],
        Task => %w[parent_id appeal_id],
        TaskTimer => ["task_id"],
        CavcRemand => %w[source_appeal_id remand_appeal_id decision_issue_ids],
        DecisionIssue => ["decision_review_id"],
        RequestIssue => %w[decision_review_id contested_decision_issue_id corrected_by_request_issue_id ineligible_due_to_id],
        RequestDecisionIssue => %w[decision_issue_id request_issue_id],
        Hearing => %w[hearing_day_id appeal_id],
        HearingTaskAssociation => %w[hearing_id hearing_task_id],
        HearingDay => [],
        VirtualHearing => ["hearing_id"],
        OrganizationsUser => []
      }
      expect(SanitizedJsonExporter::OFFSET_ID_FIELDS).to eq offset_id_fields

      expect(SanitizedJsonExporter::REASSOCIATE_FIELDS.keys).to match_array ["User", :type]
      expect(SanitizedJsonExporter::REASSOCIATE_FIELDS[:type]).to eq(Task => ["assigned_to_id"], AppealIntake => ["detail_id"])
      pp SanitizedJsonExporter::REASSOCIATE_FIELDS["User"].transform_keys(&:name)
      reassociate_fields_for_user = {
        AppealIntake => ["user_id"],
        Task => %w[assigned_by_id cancelled_by_id],
        CavcRemand => %w[updated_by_id created_by_id],
        Hearing => %w[updated_by_id judge_id created_by_id],
        HearingDay => %w[updated_by_id judge_id created_by_id],
        VirtualHearing => %w[updated_by_id created_by_id],
        OrganizationsUser => ["user_id"]
      }
      expect(SanitizedJsonExporter::REASSOCIATE_FIELDS["User"]).to eq(reassociate_fields_for_user)

      # binding.pry
      expect(SanitizedJsonExporter.fieldnames_of_typed_associations_with(Appeal, Task)).to eq ["appeal_id"]
      # known_classes = sje.records_hash.keys.map{|k| k.classify.constantize.name rescue nil }.compact - %w[User Organization]
      known_classes = (SanitizedJsonExporter::REASSOCIATE_TYPES + SanitizedJsonExporter::REASSOCIATE_TYPES_DESCENDANTS).map(&:name)
      # known_classes_descendants =  SanitizedJsonExporter::REASSOCIATE_TYPES.map{|clazz| [clazz.name, clazz.descendants.map(&:name)] if clazz.descendants.any?}.compact.to_h
      pp SanitizedJsonExporter::REASSOCIATE_TYPES.map { |clazz|
        [clazz.name, SanitizedJsonExporter.grouped_fieldnames_of_typed_associations_with(clazz, known_classes)]
      }.to_h.compact
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
        expect(SanitizedJsonExporter).to receive(:obfuscate_sentence).and_call_original.at_least(:once)
        subject
        expect(obj_hash[field_name]).to eq ""
      end
    end

    context "given array as a field value" do
      let(:field_name) { "instructions" }
      let(:obj_hash) { { field_name => ["instruct me", "me too"] } }
      it "sets a new array with new values" do
        expect(SanitizedJsonExporter).to receive(:obfuscate_sentence).and_call_original.at_least(:once)
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
    context "failure conditions" do
      describe ".sanitize" do
        it "fails for unsupported record types" do
          expect { sje.send(:sanitize, PaperTrail::Version.last) }.to raise_error RuntimeError
        end
      end
      describe ".sanitize_object_hash" do
        subject { sje.send(:sanitize_object_hash, obj_hash, fieldname_expression, appeal) }
        let(:obj_hash) { appeal.attributes }
        context "when non-existent object attribute is specified" do
          let(:fieldname_expression) { "non_existent_field" }
          it "fails" do
            expect { subject }.to raise_error RuntimeError
          end
        end
        context "when fieldname_expression is an unsupported type" do
          let(:fieldname_expression) { 1 }
          it "fails" do
            expect { subject }.to raise_error RuntimeError
          end
        end
      end
      describe ".map_value" do
        it "shows warning when transform method cannot be found for sanitization" do
          expect { sje.send(:map_value, 1234, "unknown_field_without_sanitizing_transform") }
            .to output(/WARNING: Could not find a transform_method/).to_stdout
        end
      end
    end

    shared_examples "exports appeals" do
      let(:relevant_appeals) { (appeals + [cavc_source_appeal]).uniq }
      let(:claimants) { relevant_appeals.map(&:claimants).flatten.uniq }
      let(:veterans) { relevant_appeals.map(&:veteran).uniq }
      let(:request_issues) { relevant_appeals.map(&:request_issues).flatten.uniq }
      let(:hearings) { relevant_appeals.map(&:hearings).flatten.uniq }
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

        decision_review_ids = request_issues.pluck(:decision_review_id).uniq
        expect(sje.records_hash["request_issues"].pluck("decision_review_id").uniq).to match_array decision_review_ids
        hearing_appeal_ids = hearings.pluck(:appeal_id).uniq
        expect(sje.records_hash["hearings"].pluck("appeal_id").uniq).to match_array hearing_appeal_ids
      end
    end

    let(:pii_values) do
      (task_users.pluck(:full_name, :email, :css_id).flatten +
        [
          appeal.veteran_file_number,
          appeal.veteran.file_number,
          appeal.veteran.ssn
        ]).uniq
    end

    context "when sanitize=false" do
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

        # Check PII values are not in file_contents
        expect(sje.file_contents).not_to include(*pii_values)
        # Check file_contents uses fake values instead of PII values
        expect(sje.file_contents).to include(*sje.value_mapping.values)
      end
    end
  end

  context "Importer" do
    let(:sji) do
      SanitizedJsonImporter.new(sje.file_contents).tap do |sji|
        # Causes new appeals to be created (to avoid conflict within existing appeals)
        sji.records_hash["appeals"].each { |appeal| appeal["uuid"] = SecureRandom.uuid }
      end
    end
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
      before { sje } # causes relevant appeals to be created
      it "returns nil" do
        expect_initial_state
        subject
        expect_initial_state
      end
    end

    context "when configuration provided with id_offset" do
      let(:configuration) { SanitizedJsonConfiguration.new }
      let(:sji) do
        SanitizedJsonImporter.new(sje.file_contents, configuration: configuration).tap do |sji|
          # Cause a new appeal to be created (to avoid conflict within existing appeal)
          sji.records_hash["appeals"].each { |appeal| appeal["uuid"] = SecureRandom.uuid }
        end
      end
      it "uses id_offset when importing records" do
        configuration.id_offset = 10_000
        subject
        expect(sji.imported_records[Appeal.table_name].first.id).to eq(10_000 + appeal.id)
      end
    end

    SjDifference = SanitizedJsonDifference

    context "when given 1 appeal" do
      before { sje } # causes relevant appeals to be created
      it "creates 1 appeal with associated records" do
        expect_initial_state
        subject
        record_counts = {
          "appeals" => 1,
          "veterans" => 1,
          "claimants" => 2,
          "users" => 0,
          "people" => 0,
          "organizations" => 0,
          "organizations_users" => 0,
          "tasks" => 5,
          "task_timers" => 1,
          "cavc_remands" => 0,
          "intakes" => 0,
          "decision_issues" => 0,
          "request_issues" => 0,
          "request_decision_issues" => 0
        }
        expect(sji.imported_records.transform_values(&:count)).to include record_counts
        reused_record_counts = {
          "organizations" => 2,
          "people" => 3
        }
        expect(sji.reused_records.transform_values(&:count)).to eq reused_record_counts

        expect(Appeal.count).to eq 2
        expect(Veteran.count).to eq 2
        expect(Claimant.count).to eq 4
        expect(Organization.count).to eq 2
        expect(User.count).to eq 0
        expect(Task.count).to eq 10

        # Compare differences between original records and imported records
        imported_appeal = sji.imported_records["appeals"].first
        appeal_mapped_fields = %w[id uuid veteran_file_number]
        expect(SjDifference.diff_records(appeal, imported_appeal).map(&:first)).to match_array appeal_mapped_fields

        imported_veteran = sji.imported_records["veterans"].first
        veteran_mapped_fields = %w[id file_number first_name middle_name last_name ssn]
        expect(SjDifference.diff_records(veteran, imported_veteran).map(&:first)).to match_array veteran_mapped_fields

        claimant = appeal.claimant
        imported_claimant = sji.imported_records["claimants"].last
        claimant_mapped_fields = %w[id decision_review_id]
        expect(SjDifference.diff_records(claimant, imported_claimant).map(&:first))
          .to match_array claimant_mapped_fields

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
    end

    context "when importing appeal with virtual hearing" do
      let!(:hearing_day) { create(:hearing_day) }
      let!(:hearing) do
        create(:hearing, appeal: appeal, hearing_day: hearing_day).tap do |hearing|
          create(:hearing_task_association,
                 hearing: hearing,
                 hearing_task: appeal.tasks.of_type(:HearingTask).last)
          create(:assign_hearing_disposition_task,
                 parent: hearing.hearing_task_association.hearing_task,
                 appeal: hearing.appeal)
        end
      end
      let!(:virtual_hearing) do
        create(:virtual_hearing, hearing: hearing,
                                 alias: "0123456", conference_id: 7_654_321)
      end
      before { sje } # causes relevant appeals to be created

      it "creates hearing appeal with associated records" do
        # pp sje.records_hash.transform_values(&:count)
        subject
        record_counts = { "appeals" => 1,
                          "users" => 6,
                          "organizations" => 0,
                          "intakes" => 0,
                          "veterans" => 1,
                          "claimants" => 2,
                          "people" => 0,
                          "judge_case_reviews" => 0,
                          "attorney_case_reviews" => 0,
                          "decision_documents" => 0,
                          "tasks" => 6,
                          "task_timers" => 1,
                          "organizations_users" => 0,
                          "cavc_remands" => 0,
                          "decision_issues" => 0,
                          "request_issues" => 0,
                          "request_decision_issues" => 0,
                          "hearings" => 1,
                          "hearing_task_associations" => 1,
                          "hearing_days" => 1,
                          "virtual_hearings" => 1 }
        expect(sji.imported_records.transform_values(&:count)).to eq record_counts
        reused_record_counts = {
          "organizations" => 2,
          "people" => 3
        }
        expect(sji.reused_records.transform_values(&:count)).to eq reused_record_counts

        check_all_differences(sje, sji, appeal)
      end
    end

    context "when importing CAVC remand appeal" do
      let!(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
      let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
      let(:window_task) do
        send_task = cavc_appeal.tasks.open.of_type(:SendCavcRemandProcessedLetterTask).last
        child_send_task = create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin)
        child_send_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin)

        cavc_appeal.tasks.of_type(:CavcRemandProcessedLetterResponseWindowTask).first
      end

      let!(:sje) do
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
        expect(User.count).to eq 6
        expect(DecisionDocument.count).to eq 1
        expect(Task.count).to eq 16
        expect(TaskTimer.count).to eq 2

        subject
        record_counts = {
          "appeals" => 2,
          "veterans" => 1,
          "claimants" => 2,
          "users" => 6,
          "organizations" => 0,
          "organizations_users" => 0,
          "decision_documents" => 1,
          "tasks" => 16,
          "task_timers" => 2,
          "cavc_remands" => 1,
          "decision_issues" => 3,
          "request_issues" => 6,
          "request_decision_issues" => 3
        }
        expect(sji.imported_records.transform_values(&:count)).to include record_counts
        reused_record_counts = {
          "organizations" => 4,
          "organizations_users" => 3,
          "people" => 1
        }
        expect(sji.reused_records.transform_values(&:count)).to eq reused_record_counts

        expect(Appeal.count).to eq 4
        expect(Veteran.count).to eq 2
        expect(Claimant.count).to eq 4
        expect(Organization.count).to eq 8 # existing orgs are reused
        expect(User.count).to eq 12
        expect(Task.count).to eq 32
        expect(TaskTimer.count).to eq 4

        # Check users and orgs associated with tasks exists
        imported_appeals = sji.imported_records["appeals"]
        imported_appeals.map(&:tasks).flatten.each do |task|
          expect(task.assigned_by).not_to be_nil if task.assigned_by_id
          expect(task.assigned_to).not_to be_nil if task.assigned_to_id
        end

        check_all_differences(sje, sji, cavc_source_appeal, cavc_appeal)
      end
    end

    def check_all_differences(sje, sji, *orig_appeals)
      not_processed_counts = sje.records_hash.transform_values(&:count).to_a -
                             sji.imported_records.transform_values(&:count).to_a -
                             sji.reused_records.transform_values(&:count).to_a
      expect(not_processed_counts).to include ["metadata", 1]

      # pp "DIFFERENCES counts", sji.differences(orig_appeals, ignore_expected_diffs: false).transform_values(&:count)
      # pp sji.differences(orig_appeals, ignore_expected_diffs: false)
      diffs = sji.differences(orig_appeals, additional_expected_diffs_fields: { Appeal => ["uuid"] })
      # pp "DIFFERENCES minus expected diffs", diffs
      expect(diffs.values.flatten).to be_empty
    end
  end
end
