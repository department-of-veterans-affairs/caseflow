# frozen_string_literal: true

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:veteran) { create(:veteran) }
  let!(:event) { double("Event", reference_id: 1) }
  let!(:end_product_establishment) do
    create(:end_product_establishment,
           :active,
           reference_id: 1,
           veteran_file_number: veteran.file_number)
  end
  describe "#call" do
    context "when veteran is also a claimant" do
      it "returns the id of the existing claimant" do
        claimant = create(:claimant, person: veteran.person)
        allow(event).to receive(:veteran).and_return(veteran)
        service = described_class.new(event)
        expect(service.call).to eq(claimant.id)
      end
    end

    context "when veteran is not a claimant" do
      it "creates a new claimant and returns its id" do
        allow(event).to receive(:veteran).and_return(veteran)
        service = described_class.new(event)
        expect { service.call }.to change { VeteranClaimant.count }.by(1)
      end

      it "returns the id of the newly created claimant" do
        allow(event).to receive(:veteran).and_return(veteran)
        service = described_class.new(event)
        expect(service.call).to eq(VeteranClaimant.last.id)
      end
    end
  end
end
