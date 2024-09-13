# frozen_string_literal: true

require "appeals_in_location_63_in_past_2_days"

RSpec.describe AppealsInLocation63InPast2Days do
  describe "#loc_63_appeals" do
    let(:docket_coordinator) { instance_double(DocketCoordinator) }
    let(:docket) { instance_double(Docket) }

    before do
      allow(DocketCoordinator).to receive(:new).and_return(docket_coordinator)
    end

    context "when dockets hash contains a legacy docket" do
      let(:appeals) do
        [
          {
            "bfkey": "915660066",
            "tinum": "150000915660066",
            "snamef": "Bob",
            "snamel": "Smithkreiger",
            "ssn": "400797580",
            "vlj_namef": "Some-moved",
            "vlj_namel": "some-not"
          },
          {
            "bfkey": "520100077",
            "tinum": "150000520100077",
            "snamef": "Bob",
            "snamel": "Smithritchie",
            "ssn": "244382041",
            "vlj_namef": "Some-moved",
            "vlj_namel": "some-not"
          }
        ]
      end

      let(:legacy_docket) { instance_double(LegacyDocket) }

      before do
        allow(docket_coordinator).to receive(:dockets).and_return(legacy: legacy_docket)
        allow(legacy_docket).to receive(:loc_63_appeals).and_return(appeals)
        allow(described_class).to receive(:legacy_rows).with(appeals).and_return(appeals)
      end

      it "returns unique legacy rows based on docket_number" do
        result = described_class.loc_63_appeals
        expect(result).to eq([{ bfkey: "915660066",
                                snamef: "Bob",
                                snamel: "Smithkreiger",
                                ssn: "400797580",
                                tinum: "150000915660066",
                                vlj_namef: "Some-moved",
                                vlj_namel: "some-not" }])
      end
    end

    context "when dockets hash does not contain a legacy docket" do
      before do
        allow(docket_coordinator).to receive(:dockets).and_return(other_key: docket)
      end

      it "returns an empty array" do
        result = described_class.loc_63_appeals
        expect(result).to eq([])
      end
    end
  end
end
