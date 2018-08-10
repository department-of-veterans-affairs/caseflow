describe PowerOfAttorneyMapper do
  let(:poa_mapper) { Class.new { include PowerOfAttorneyMapper } }

  describe "Maps VACOLS POA to POA" do
    context "#get_poa_from_vacols_poa" do
      it "returns None if there's no rep" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "L")
        expect(poa[:vacols_representative_type]).to eq("None")
      end

      it "returns organization info if vacols case record contains it" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "M")
        expect(poa[:vacols_org_name]).to eq("Navy Mutual Aid Association")
        expect(poa[:vacols_representative_type]).to eq("Service Organization")
      end

      it "returns poa from rep table if rep name is found in rep table" do
        representative_record = OpenStruct.new(repfirst: "Brad", repmi: "B", replast: "Pitt", reptype: "G")
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "O", rep_record: representative_record)
        expect(poa[:vacols_first_name]).to eq("Brad")
        expect(poa[:vacols_representative_type]).to eq("Agent")
      end

      it "returns blank for name and type if vacols case record points to rep table but rep record is nil" do
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "U")
        expect(poa[:vacols_first_name]).to eq nil
        expect(poa[:vacols_representative_type]).to eq(nil)
      end

      it "returns name from rep table if vacols code is blank but rep record exists" do
        representative_record = OpenStruct.new(repfirst: "Brad", repmi: "B", replast: "Pitt")
        poa = poa_mapper.new.get_poa_from_vacols_poa(vacols_code: "", rep_record: representative_record)
        expect(poa[:vacols_representative_type]).to eq nil
        expect(poa[:vacols_last_name]).to eq("Pitt")
      end
    end

    context "#get_poa_from_bgs_poa" do
      let(:attorney_poa) { { power_of_attorney: { nm: "Steve Holtz", org_type_nm: "POA Attorney" } } }
      let(:unknown_type_poa) { { power_of_attorney: { nm: "Mrs. Featherbottom", org_type_nm: "unfamiliar_type" } } }
      let(:no_poa) { { message: "No POA found for 1234567" } }

      it "maps BGS rep type to our rep type" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(attorney_poa[:power_of_attorney])
        expect(poa[:representative_name]).to eq("Steve Holtz")
        expect(poa[:representative_type]).to eq("Attorney")
      end

      it "classifies rep type as 'Other' if we haven't categorized it" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(unknown_type_poa[:power_of_attorney])
        expect(poa[:representative_name]).to eq("Mrs. Featherbottom")
        expect(poa[:representative_type]).to eq("Other")
      end

      it "when no poa is found" do
        poa = poa_mapper.new.get_poa_from_bgs_poa(no_poa[:power_of_attorney])
        expect(poa).to eq({})
      end
    end
  end

  describe "Maps POA to VACOLS rep code" do
    context "#get_vacols_rep_code_from_poa" do
      it "is nil when representative type is not found" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("TGDF", "PARALYZED VETERANS OF AMERICA")
        expect(code).to be nil
      end

      it "maps rep name to vacols code when rep type is a service organization" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("Service Organization", "PARALYZED VETERANS OF AMERICA")
        expect(code).to eq "G"
      end

      it "maps to 'Other' when rep type is a service org and rep name is not found" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("ORGANIZATION", "NONEXISTENT NAME")
        expect(code).to eq "O"
      end

      it "handles cases where rep type is not a service org" do
        code = poa_mapper.new.get_vacols_rep_code_from_poa("Attorney", "Susan Ross")
        expect(code).to eq "T"
      end
    end
  end
end
