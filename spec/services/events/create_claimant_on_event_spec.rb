# frozen_string_literal: true

RSpec.describe Events::CreateClaimantOnEvent do
  let(:event) { create(:event) } # Adjust this to create an event with necessary attributes

  describe "#call" do
    context "when veteran is also a claimant" do
      it "returns the id of the existing claimant" do
        claimant = create(:claimant, person: event.veteran.person) # Create an existing claimant for the veteran
        service = described_class.new(event)
        expect(service.call).to eq(claimant.id)
      end
    end

    context "when veteran is not a claimant" do
      it "creates a new claimant and returns its id" do
        service = described_class.new(event)
        expect { service.call }.to change { VeteranClaimant.count }.by(1)
      end

      it "returns the id of the newly created claimant" do
        service = described_class.new(event)
        expect(service.call).to eq(VeteranClaimant.last.id)
      end
    end
  end
end
