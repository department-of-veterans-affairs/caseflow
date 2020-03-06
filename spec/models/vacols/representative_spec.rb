# frozen_string_literal: true

describe VACOLS::Representative, :all_dbs do
  let(:vacols_case) { create(:case_with_rep_table_record) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:rep) { VACOLS::Representative.appellant_representative(appeal.vacols_id) }

  context ".appellant_representative" do
    it "will fetch only a row with an appellant reptype" do
      appellant_reptypes = VACOLS::Representative.appellant_reptypes
      expect(appellant_reptypes).to include rep.reptype
    end
  end

  context ".representatives" do
    it "will fetch an array" do
      expect(VACOLS::Representative.representatives(appeal.vacols_id).length).to eq(1)
    end
  end

  context ".update_vacols_rep_table!" do
    let(:name_hash) { { first_name: "Jill", middle_initial: "", last_name: "Ill" } }
    let(:address_hash) { { address_one: "123 Walnut Ln", address_two: "", city: "Oh", state: "OH", zip: "12222" } }

    it "will update existing rep row" do
      VACOLS::Representative.update_vacols_rep_table!(
        bfkey: appeal.vacols_id,
        name: name_hash,
        address: address_hash,
        type: :appellant_agent
      )

      expect(rep.repfirst).to eq(name_hash[:first_name])
      expect(rep.repaddr1).to eq(address_hash[:address_one])
    end

    it "will create rep row if none exists" do
      bfkey = "99999XYZ"

      expect(VACOLS::Representative.representatives(bfkey).length).to eq(0)

      VACOLS::Representative.update_vacols_rep_table!(
        bfkey: bfkey,
        name: name_hash,
        address: address_hash,
        type: :contesting_claimant
      )

      expect(VACOLS::Representative.representatives(bfkey).first.reptype).to eq("C")
      expect(VACOLS::Representative.representatives(bfkey).first.repkey).to eq(bfkey)
      expect(VACOLS::Representative.representatives(bfkey).length).to eq(1)
    end
  end

  context ".update" do
    let(:vacols_rep) { build(:representative) }

    it "will raise error" do
      expect { vacols_rep.update!(reptype: "F") }.to raise_error(VACOLS::Representative::RepError)

      expect { vacols_rep.update(reptype: "F") }.to raise_error(VACOLS::Representative::RepError)

      expect { vacols_rep.delete }.to raise_error(VACOLS::Representative::RepError)

      expect { vacols_rep.destroy }.to raise_error(VACOLS::Representative::RepError)
    end
  end

  context "when name or address contains non-ASCII characters" do
    let(:name_hash) { { first_name: "Søren", middle_initial: "A", last_name: "Skarsgård" } }
    let(:address_hash) do
      {
        address_one: "123 Walnut Aveñue",
        address_two: "«456»",
        city: "San Juañ",
        state: "OH",
        zip: "12222"
      }
    end
    let(:bfkey) { "99999XYZ" }

    subject do
      VACOLS::Representative.update_vacols_rep_table!(
        bfkey: bfkey,
        name: name_hash,
        address: address_hash,
        type: :appellant_agent
      )
    end
    context "row does not yet exist" do
      it "creates with ASCII" do
        subject

        rep = VACOLS::Representative.representatives(bfkey).first

        expect(rep.repfirst).to eq("Soren")
        expect(rep.replast).to eq("Skarsgard")
        expect(rep.repaddr1).to eq("123 Walnut Avenue")
        expect(rep.repaddr2).to eq("<<456>>")
        expect(rep.repcity).to eq("San Juan")
      end
    end

    context "row exists" do
      let(:bfkey) { appeal.vacols_id }

      it "updates with ASCII" do
        subject

        expect(rep.repfirst).to eq("Soren")
        expect(rep.replast).to eq("Skarsgard")
        expect(rep.repaddr1).to eq("123 Walnut Avenue")
        expect(rep.repaddr2).to eq("<<456>>")
        expect(rep.repcity).to eq("San Juan")
      end
    end

    context "name contains invalid UTF-8 codepoint from bad Windows 1252 conversion" do
      let(:bfkey) { appeal.vacols_id }
      let(:name_hash) { { first_name: "Søren", middle_initial: "A", last_name: "O\x92Reilly" } }

      it "corrects codepoint before transliterating to ASCII" do
        subject

        expect(rep.replast).to eq("O'Reilly")
      end
    end
  end
end
