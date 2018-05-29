describe Appeal do
  context "#find_appeal_or_legacy_appeal_by_id" do
    context "with a uuid (AMA appeal id)" do
      let(:veteran_file_number) { "64205050" }
      let(:appeal) do
        create(:appeal, veteran_file_number: veteran_file_number)
      end

      it "finds the appeal" do
        expect(Appeal.find_appeal_or_legacy_appeal_by_id(appeal.uuid)).to \
          eq(appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_uuid = "11111111-aaaa-bbbb-CCCC-999999999999"
        expect{ Appeal.find_appeal_or_legacy_appeal_by_id(made_up_uuid) }.to \
          raise_exception(ActiveRecord::RecordNotFound, "Couldn't find Appeal")
      end
    end

    context "with a legacy appeal" do
      let(:vacols_id) { "1234567" }
      let(:legacy_appeal) do
        create(:legacy_appeal, vacols_id: vacols_id, vbms_id: "111223333S")
      end

      it "finds the appeal" do
        legacy_appeal.save
        expect(Appeal.find_appeal_or_legacy_appeal_by_id(vacols_id)).to \
          eq(legacy_appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_non_uuid = "9876543"
        expect do
          Appeal.find_appeal_or_legacy_appeal_by_id(made_up_non_uuid)
        end.to \
          raise_exception(
            ActiveRecord::RecordNotFound,
            "Couldn't find LegacyAppeal"
          )
      end
    end
  end
end
