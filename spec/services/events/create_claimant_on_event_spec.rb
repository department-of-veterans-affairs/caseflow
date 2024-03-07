RSpec.describe Events::CreateClaimantOnEvent do
  describe ".process" do
    let(:event) { double("Event", reference_id: 1) }
    let(:claimant_attributes) do
      {
        name_siffix: "name_suffix",
        participant_id: "participant_id_value",
        payee_code: "payee_code_value",
        source_type: "source_type_value"
      }
    end

    context "when is_veteran_claimant is true" do
      it "returns the event reference id" do
        result = described_class.process(event: event, claimant_attributes: claimant_attributes, is_veteran_claimant: true)
        expect(result).to eq(event.reference_id)
      end
    end

    context "when is_veteran_claimant is false" do
      let(:claimant) { instance_double(Claimant, id: 1) }

      before do
        allow(Claimant).to receive(:create!).and_return(claimant)
        allow(EventRecord).to receive(:create!)
      end

      it "creates a new claimant and returns its id" do
        expect(Claimant).to receive(:create!).with(
          name_suffix: claimant_attributes[:name_suffix],
          participant_id: claimant_attributes[:participant_id],
          payee_code: claimant_attributes[:payee_code],
          type: claimant_attributes[:source_type]
        ).and_return(claimant)

        expect(EventRecord).to receive(:create!).with(event: event, backfill_record: claimant)

        result = described_class.process(event: event, claimant_attributes: claimant_attributes, is_veteran_claimant: false)
        expect(result).to eq(claimant.id)
      end
    end
  end
end
