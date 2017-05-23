describe PowerOfAttorneyMapper do
  let(:poa_mapper) { Class.new { include PowerOfAttorneyMapper } }

  describe "Maps VACOLS POA to POA" do
    context "#get_short_name" do
      let(:short_name) { poa_mapper.new.get_short_name("O") }
      it "returns short name" do
        expect(short_name).to eq("Other")
      end
    end

    context "#get_full_name" do
      let(:full_name) { poa_mapper.new.get_full_name("B") }
      it "returns full name" do
        expect(full_name).to eq("AMVETS")
      end
    end

    context "#get_poa_from_vacols_poa" do
      it "returns None if there's no rep" do
        poa = poa_mapper.new.get_poa_from_vacols_poa("L")
        expect(poa[:representative_type]).to eq("None")
      end

      it "returns poa if rep name is found in vacols case record" do
        poa = poa_mapper.new.get_poa_from_vacols_poa("M")
        expect(poa[:representative_name]).to eq("Navy Mutual Aid Association")
        expect(poa[:representative_type]).to eq("Service Organization")
      end

      it "returns poa if rep name is found in rep table" do
        poa = poa_mapper.new.get_poa_from_vacols_poa("T")
        # TODO: finish when we implement this
        expect(poa[:representative_name]).to eq("Stub POA Name")
        expect(poa[:representative_type]).to eq("Stub POA Type")
      end
    end

    context "#get_poa_from_bgs_poa" do
      let(:attorney_poa) { { power_of_attorney: { nm: "Steve Holtz", org_type_nm: "POA Attorney" } } }
      let(:unknown_type_poa) { { power_of_attorney: { nm: "Mrs. Featherbottom", org_type_nm: "unfamiliar_type" } } }

      it "maps BGS rep type to our rep type" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(attorney_poa)
        expect(poa[:representative_name]).to eq("Steve Holtz")
        expect(poa[:representative_type]).to eq("Attorney")
      end

      it "classifies rep type as 'Other' if we haven't categorized it" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(unknown_type_poa)
        expect(poa[:representative_name]).to eq("Mrs. Featherbottom")
        expect(poa[:representative_type]).to eq("Other")
      end
    end
  end
end
