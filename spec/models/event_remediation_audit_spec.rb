# frozen_string_literal: true

RSpec.describe EventRemediationAudit, type: :model do
  let(:event_record) { create(:event_record) } # event_record factory creates an event within it
  let(:remediated_record) { create(:appeal) } # A valid remediated record (use a valid model here)

  context "when remediation_type is valid" do
    valid_remediation_types = %w[
      VeteranRecordRemediationService
      DuplicatePersonRemediationService
    ]

    valid_remediation_types.each do |valid_remediation_type|
      it "is valid with remediation_type: #{valid_remediation_type}" do
        # Define the after_data and before_data as simple hashes to test that functionality
        after_data = { "status" => "completed" }
        before_data = { "status" => "pending" }

        event_remediation_audit = EventRemediationAudit.new(
          event_record: event_record,
          remediated_record_type: remediated_record.class.name,
          remediated_record_id: remediated_record.id,
          info: {
            remediation_type: valid_remediation_type,
            after_data: before_data,
            before_data: after_data
          }
        )

        expect(event_remediation_audit).to be_valid
      end
    end
  end

  context "when info contains a valid remediation_type" do
    it "creates an EventRemediationAudit with remediation_type 'DuplicatePersonRemediationService'" do
      after_data = { "status" => "completed" }
      before_data = { "status" => "pending" }

      remediated_record = create(:appeal) # Replace with any valid remediated record
      event_remediation_audit = EventRemediationAudit.create!(
        event_record: event_record,
        remediated_record_type: remediated_record.class.name,
        remediated_record_id: remediated_record.id,
        info: {
          remediation_type: "DuplicatePersonRemediationService",
          after_data: after_data,
          before_data: before_data
        }
      )

      expect(event_remediation_audit).to be_persisted
      expect(event_remediation_audit.info["remediation_type"]).to eq("DuplicatePersonRemediationService")
      expect(event_remediation_audit.info["after_data"]).to eq(after_data)
      expect(event_remediation_audit.info["before_data"]).to eq(before_data)
    end
  end

  context "when remediation_type is invalid" do
    it "is invalid with an unknown remediation_type" do
      # Define the after_data and before_data as simple hashes
      after_data = { "status" => "completed" }
      before_data = { "status" => "pending" }

      event_remediation_audit = EventRemediationAudit.new(
        event_record: event_record,
        remediated_record_type: remediated_record.class.name,
        remediated_record_id: remediated_record.id,
        info: {
          remediation_type: "NonExistentRemediationService", # Invalid type
          after_data: after_data,
          before_data: before_data
        }
      )

      expect(event_remediation_audit).to be_invalid
      expect(event_remediation_audit.errors[:info]).to include("remediation_type is not valid")
    end
  end

  context "when remediated_record_type is invalid" do
    it "is invalid with an unknown remediated_record_type" do
      after_data = { "status" => "completed" }
      before_data = { "status" => "pending" }

      # Create EventRemediationAudit with an invalid remediated_record_type
      event_remediation_audit = EventRemediationAudit.new(
        event_record: event_record,
        remediated_record_type: "InvalidRemediatedRecordType",  # Invalid remediated record type
        remediated_record_id: remediated_record.id,
        info: {
          remediation_type: "VeteranRecordRemediationService",  # Valid type
          after_data: after_data,
          before_data: before_data
        }
      )

      expect(event_remediation_audit).to be_invalid
      expect(event_remediation_audit.errors[:remediated_record_type]).to include("is not a valid remediated record type")
    end
  end
end
