describe VACOLS::Representative do
  let(:vacols_case) { create(:case_with_rep_table_record) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:rep) { VACOLS::Representative.appellant_representative(appeal.vacols_id) }

  context ".appellant_representative" do
    it "will fetch only a row with an appellant reptype" do
      appellant_reptypes = VACOLS::Representative.appellant_reptypes
      expect(appellant_reptypes.include?(rep.reptype)).to eq true
    end
  end

  context ".representatives" do
    it "will fetch an array" do
      expect(VACOLS::Representative.representatives(appeal.vacols_id).length).to eq(1)
    end
  end
end
