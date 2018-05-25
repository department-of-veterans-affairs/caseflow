describe Appeal do
  context "#find_appeal_or_legacy_appeal_by_id" do
    context "with a uuid (AMA appeal id)" do
      let(:veteran_file_number) { "64205050" }
      let(:appeal) do
        Appeal.create!(
          veteran_file_number: veteran_file_number,
          uuid: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
        )
      end

      it "finds the appeal" do
        expect(Appeal.find_appeal_or_legacy_appeal_by_id(appeal.uuid)).to eq(appeal)
      end

      it "return nil for a non-existant one" do
        expect(Appeal.find_appeal_or_legacy_appeal_by_id("11111111-aaaa-bbbb-CCCC-999999999999")).to be_nil
      end
    end

    context "with a legacy appeal" do
      let(:veteran_file_number) { "111223333" }
      let(:legacy_appeal) do
        Generators::LegacyAppeal.build(
          vacols_id: "1234567",
          vbms_id: "111223333S",
          type: "Original",
          decision_date: 365.days.ago.to_date,
          issues: [
            Generators::Issue.build(codes: %w[02 01]),
            Generators::Issue.build(codes: %w[02 02]),
            Generators::Issue.build(codes: %w[02 03])
          ]
        )
      end

      it "finds the appeal" do
        legacy_appeal.save
        expect(Appeal.find_appeal_or_legacy_appeal_by_id(veteran_file_number)).to
        eq([legacy_appeal])
      end
    end
  end
end
