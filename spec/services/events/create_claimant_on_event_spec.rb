# frozen_string_literal: true

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { double("Event", reference_id: 1) }
  let(:vbms_claimant) do
    {
      "claim_review" => {
        "veteran_is_not_claimant" => true
      },
      "claimant" => {
        "name_suffix" => "Jr.",
        "participant_id" => "12345",
        "payee_code" => "01",
        "type" => "individual"
      }
    }
  end

  describe ".process" do
    context "when veteran is not the claimant" do
      it "creates a new claimant and returns its id" do
        expect(Claimant).to receive(:find_or_create_by!).with(
          name_suffix: "Jr.",
          participant_id: "12345",
          payee_code: "01",
          type: "individual"
        ).and_return(double("Claimant", id: 123))

        expect(EventRecord).to receive(:create!).with(
          event: event,
          backfill_record: anything
        )

        expect(described_class.process(event: event, vbms_claimant: vbms_claimant)).to eq(123)
      end

      it "does not create a new claimant if veteran is the claimant" do
        vbms_claimant["claim_review"]["veteran_is_not_claimant"] = false

        expect(Claimant).not_to receive(:find_or_create_by!)

        expect(EventRecord).not_to receive(:create!)

        expect(described_class.process(event: event, vbms_claimant: vbms_claimant)).to be_nil
      end
    end
  end
end
