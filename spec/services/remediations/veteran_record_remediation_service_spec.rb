# frozen_string_literal: true


describe Remediations::VeteranRecordRemediationService do
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
      EndProductEstablishment => "reference_id",
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

    before do
      allow(vet_record_service).to receive(:grab_collections).with(before_fn).and_return(mock_classes)
    end

    it "updates each associated object's file_number to the new value" do
      mock_classes.each do |mock_instance|
        column = column_mapping[mock_instance.class]
        expect(mock_instance).to receive(:update!).with(after_fn).and_wrap_original do
          mock_instance.send("#{column}=", after_fn)
        end
      end

      vet_record_service.remediate!

      mock_classes.each do |mock_instance|
        column = column_mapping[mock_instance.class]
        expect(mock_instance.send(column)).to eq(after_fn)
      end
    end
  end
end


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
