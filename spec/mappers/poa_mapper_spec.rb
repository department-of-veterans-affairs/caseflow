describe PoaMapper do
  describe "Maps VACOLS POA to POA" do
    context "#get_short_name" do
      it "returns short name" do
        let(:short_name) { PoaMapper.get_short_name("E") }
        expect(short_name).to eq("Other")
      end
    end

    context "#get_full_name" do
      it "returns full name" do
        let(:full_name) { PoaMapper.get_full_name("A") }
        expect(full_name).to eq("AMVETS")
      end
    end

    context "#get_poa_from_vacols_poa" do
      it "returns None if there's no rep" do
        let(:poa) { PoaMapper.get_poa_from_vacols_poa("F") }
        expect(poa[:represenative_type]).to eq("None")
      end

      it "returns poa if rep name is found in vacols case record" do
        let(:poa) { PoaMapper.get_poa_from_vacols_poa("M") }
        expect(poa[:represenative_type]).to eq("Navy Mutual Aid Association")
      end

      it "returns poa if rep name is found in rep table" do
        let(:poa) { PoaMapper.get_poa_from_vacols_poa("T") }
        # TODO: finish when we implement this
        # expect(poa[:represenative_type]).to eq("FILL IN")
      end
    end
  end
end
