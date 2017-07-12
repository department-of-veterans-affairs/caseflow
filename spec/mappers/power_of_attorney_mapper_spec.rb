describe PowerOfAttorneyMapper do
  let(:poa_mapper) { Class.new { include PowerOfAttorneyMapper } }

  describe "Maps VACOLS POA to POA" do
    context "#get_poa_from_vacols_poa" do
      it "returns None if there's no rep" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "L")
        expect(poa[:representative_type]).to eq("None")
      end

      it "returns poa if rep name is found in vacols case record" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "M")
        expect(poa[:representative_name]).to eq("Navy Mutual Aid Association")
        expect(poa[:representative_type]).to eq("Service Organization")
      end

      it "returns poa if rep name is found in rep table" do
        representative_record = OpenStruct.new(repfirst: "Brad", repmi: "B", replast: "Pitt")
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "O", representative_record: representative_record)
        expect(poa[:representative_name]).to eq("Brad B Pitt")
        expect(poa[:representative_type]).to eq("Other")
      end

      it "returns blank for representative_name if first and last names are blank in rep table" do
        representative_record = OpenStruct.new(repmi: "B")
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "T", representative_record: representative_record)
        expect(poa[:representative_name]).to eq nil
        expect(poa[:representative_type]).to eq("Attorney")
      end

      it "returns blank for representative_name if representative record is nil" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "U")
        expect(poa[:representative_name]).to eq nil
        expect(poa[:representative_type]).to eq("Agent")
      end

      it "returns name from rep table if vacols code is blank" do
        representative_record = OpenStruct.new(repfirst: "Brad", repmi: "B", replast: "Pitt")
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: " ", representative_record: representative_record)
        expect(poa[:representative_type]).to eq nil
        expect(poa[:representative_name]).to eq("Brad B Pitt")
      end
    end

    context "#get_poa_from_bgs_poa" do
      let(:attorney_poa) { { power_of_attorney: { nm: "Steve Holtz", org_type_nm: "POA Attorney" } } }
      let(:unknown_type_poa) { { power_of_attorney: { nm: "Mrs. Featherbottom", org_type_nm: "unfamiliar_type" } } }
      let(:no_poa) { { message: "No POA found for 1234567" } }

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

      it "when no poa is found" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(no_poa)
        expect(poa).to be {}
      end
    end
  end

  describe "Maps POA to VACOLS rep code" do
    context "#get_vacols_rep_code_from_poa" do
      it "uses rep type to map to Vacols code when rep type is not a service org" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("ARC", "PARALYZED VETERANS OF AMERICA")
        expect(code).to eq "C"
      end
      it "is nil when representative type is not found" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("TGDF", "PARALYZED VETERANS OF AMERICA")
        expect(code).to be nil
      end
      it "maps rep name to vacols code when rep type is a service organization" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("Service Organization", "PARALYZED VETERANS OF AMERICA")
      end

      it "maps to 'Other' when rep type is a service org and rep name is not found" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("TGDF", "NONEXISTENT NAME")
      end
    end
  end
end
