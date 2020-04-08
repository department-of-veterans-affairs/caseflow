# frozen_string_literal: true

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

    context "#get_hash_of_poa_from_bgs_poas" do
      let(:participant_id) { "123456" }
      let(:second_participant_id) { "7890" }

      it "returns representative information if there's a rep" do
        poas = poa_mapper.new.get_hash_of_poa_from_bgs_poas(
          [
            {
              ptcpnt_id: participant_id,
              power_of_attorney: {
                legacy_poa_cd: "071",
                nm: "TEST ORG",
                org_type_nm: "POA National Organization",
                ptcpnt_id: "2452383"
              }
            },
            {
              ptcpnt_id: second_participant_id,
              power_of_attorney: {
                legacy_poa_cd: "072",
                nm: "DIFFERENT ORG",
                org_type_nm: "POA National Organization",
                ptcpnt_id: "2452384"
              }
            }
          ]
        )
        expect(poas[participant_id][:representative_name]).to eq("TEST ORG")
        expect(poas[second_participant_id][:representative_name]).to eq("DIFFERENT ORG")
      end

      it "returns none if there's no rep" do
        poas = poa_mapper.new.get_hash_of_poa_from_bgs_poas(
          message: "No POA found for 2452383", ptcpnt_id: "2452383"
        )
        expect(poas["2452383"]).to be_empty
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
        expect(poa).to eq({})
      end
    end
  end

  context "#get_limited_poas_hash_from_bgs" do
    context "when the response is nil" do
      let(:bgs_response) { nil }

      it "returns nil" do
        limited_poas = poa_mapper.get_limited_poas_hash_from_bgs(bgs_response)
        expect(limited_poas).to be_nil
      end
    end

    context "when a single limited poa is returned" do
      let(:bgs_response) { { authzn_poa_access_ind: "Y", bnft_claim_id: "600130321", poa_cd: "OU3" } }

      it "returns a hash keyed by claim id" do
        limited_poas = poa_mapper.get_limited_poas_hash_from_bgs(bgs_response)
        expect(limited_poas).to eq(
          "600130321" => { limited_poa_code: "OU3", limited_poa_access: "Y" }
        )
      end
    end

    context "when an array of multiple limited poas are returned" do
      let(:bgs_response) do
        [
          { authzn_poa_access_ind: "Y", bnft_claim_id: "600130321", poa_cd: "OU3" },
          { authzn_poa_access_ind: "Y", bnft_claim_id: "600137450", poa_cd: "084" },
          { authzn_change_clmant_addrs_ind: "N", authzn_poa_access_ind: "N", bnft_claim_id: "600149269", poa_cd: "007" }
        ]
      end

      it "returns a hash keyed by claim id" do
        limited_poas = poa_mapper.get_limited_poas_hash_from_bgs(bgs_response)

        expect(limited_poas).to eq(
          "600130321" => { limited_poa_code: "OU3", limited_poa_access: "Y" },
          "600137450" => { limited_poa_code: "084", limited_poa_access: "Y" },
          "600149269" => { limited_poa_code: "007", limited_poa_access: "N" }
        )
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
