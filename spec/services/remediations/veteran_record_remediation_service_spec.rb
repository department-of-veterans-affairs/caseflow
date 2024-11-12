# frozen_string_literal: true

RSpec.describe Remediations::VeteranRecordRemediationService do
  let(:before_fn) { "12345" }
  let(:after_fn) { "54321" }
  let(:vet_record_service) { described_class.new(before_fn, after_fn) }

  # Define a mapping of classes to their file number columns
  let(:column_mapping) do
    {
      Appeal => "veteran_file_number",
      AvailableHearingLocations => "veteran_file_number",
      BgsPowerOfAttorney => "file_number",
      Document => "file_number",
      EndProductEstablishment => "veteran_file_number",
      Form8 => "file_number",
      HigherLevelReview => "veteran_file_number",
      Intake => "veteran_file_number",
      LegacyAppeal => "vbms_id",
      RampElection => "veteran_file_number",
      RampRefiling => "veteran_file_number",
      SupplementalClaim => "veteran_file_number"
    }
  end

  describe "#remediate!" do
    let(:mock_classes) do
      Remediations::VeteranRecordRemediationService::ASSOCIATED_OBJECTS.map do |klass|
        mock_instance = klass.new
        column = column_mapping[klass]
        mock_instance.send("#{column}=", before_fn)
        allow(FixFileNumberWizard::Collection).to receive(:new).with(klass, before_fn).and_return(mock_instance)
        mock_instance
      end
    end

    let(:mock_veteran) { instance_double("Veteran", ssn: "123456789", id: 1, file_number: before_fn) }
    let(:duplicate_veteran) { instance_double("Veteran", ssn: "123456789", id: 2, file_number: before_fn) }

    before do
      # Stub Veteran.find_by_file_number to handle both before_fn and after_fn
      allow(Veteran).to receive(:find_by_file_number).with(before_fn).and_return(mock_veteran)
      allow(Veteran).to receive(:find_by_file_number).with(after_fn).and_return(mock_veteran)

      # Stub Veteran.where to return mock_veteran and duplicate_veteran for the same SSN
      allow(Veteran).to receive(:where).with(ssn: "123456789").and_return([mock_veteran, duplicate_veteran])

      # Stub destroy! on duplicate_veteran to prevent failure
      allow(duplicate_veteran).to receive(:destroy!).and_return(nil)

      # Allow grab_collections to return mock classes
      allow(vet_record_service).to receive(:grab_collections).with(before_fn).and_return(mock_classes)
    end

    context "when there are duplicate veterans" do
      it "runs dup_fix and updates the file_number for duplicates" do
        # We expect the `dup_fix` method to be called and the collections for the duplicate veterans to be updated.
        expect(vet_record_service).to receive(:dup_fix).with(after_fn).and_call_original

        mock_classes.each do |mock_instance|
          column = column_mapping[mock_instance.class]
          expect(mock_instance).to receive(:update!).with(after_fn).and_wrap_original do
            mock_instance.send("#{column}=", after_fn)
          end
        end

        # talk to raymond about this
        expect(duplicate_veteran).to receive(:destroy!).and_return(nil)

        vet_record_service.remediate!

        # Verify that all mock instances' file numbers are updated
        mock_classes.each do |mock_instance|
          column = column_mapping[mock_instance.class]
          expect(mock_instance.send(column)).to eq(after_fn)
        end
      end
    end

    context "when there are no duplicate veterans" do
      before do
        # Ensure no duplicates exist for the `before_fn`
        allow(Veteran).to receive(:where).with(ssn: "123456789").and_return([mock_veteran])
      end

      it "does not run dup_fix and updates file_number normally" do
        # Expect that `dup_fix` should not be called in this scenario.
        expect(vet_record_service).not_to receive(:dup_fix)

        mock_classes.each do |mock_instance|
          column = column_mapping[mock_instance.class]
          expect(mock_instance).to receive(:update!).with(after_fn).and_wrap_original do
            mock_instance.send("#{column}=", after_fn)
          end
        end

        vet_record_service.remediate!

        # Verify that all mock instances' file numbers are updated
        mock_classes.each do |mock_instance|
          column = column_mapping[mock_instance.class]
          expect(mock_instance.send(column)).to eq(after_fn)
        end
      end
    end
  end
end

# -----------------------------
# Below is the test that we made before adding the dup_fix method

# RSpec.describe Remediations::VeteranRecordRemediationService do
#   let(:before_fn) { "12345" }
#   let(:after_fn) { "54321" }
#   let(:vet_record_service) { described_class.new(before_fn, after_fn) }

#   # Define a mapping of classes to their file number columns
#   let(:column_mapping) do
#     {
#       Appeal => "veteran_file_number",
#       AvailableHearingLocations => "veteran_file_number",
#       BgsPowerOfAttorney => "file_number",
#       Document => "file_number",
#       EndProductEstablishment => "reference_id",
#       Form8 => "file_number",
#       HigherLevelReview => "veteran_file_number",
#       Intake => "veteran_file_number",
#       LegacyAppeal => "vbms_id",
#       RampElection => "veteran_file_number",
#       RampRefiling => "veteran_file_number",
#       SupplementalClaim => "veteran_file_number"
#     }
#   end

#   describe "#remediate!" do
#     let(:mock_classes) do
#       Remediations::VeteranRecordRemediationService::ASSOCIATED_OBJECTS.map do |klass|
#         mock_instance = klass.new
#         column = column_mapping[klass]
#         mock_instance.send("#{column}=", before_fn)
#         allow(FixFileNumberWizard::Collection).to receive(:new).with(klass, before_fn).and_return(mock_instance)
#         mock_instance
#       end
#     end

#     before do
#       allow(vet_record_service).to receive(:grab_collections).with(before_fn).and_return(mock_classes)
#     end

#     it "updates each associated object's file_number to the new value" do
#       mock_classes.each do |mock_instance|
#         column = column_mapping[mock_instance.class]
#         expect(mock_instance).to receive(:update!).with(after_fn).and_wrap_original do
#           mock_instance.send("#{column}=", after_fn)
#         end
#       end

#       vet_record_service.remediate!

#       mock_classes.each do |mock_instance|
#         column = column_mapping[mock_instance.class]
#         expect(mock_instance.send(column)).to eq(after_fn)
#       end
#     end
#   end
# end

# -------------------------

# describe Remediations::VeteranRecordRemediationService do
#   let(:before_fn) { "12345" }  # Replace with appropriate test value
#   let(:after_fn) { "54321" }   # Replace with appropriate test value
#   let(:vet_record_service) { described_class.new(before_fn, after_fn) }

#   let(:vet_appeal_record) {
#     instance_double("Appeal", id: 1, veteran_file_number: 12345)
#   }

#   describe "#remediate!" do
#     it "calls fix_vet_records and performs remediation" do
#       expect(vet_record_service).to receive(:fix_vet_records).and_call_original
#       vet_record_service.remediate!
#     end
#   end
# end
