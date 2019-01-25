describe Relationship do
  let(:veteran) { create(:veteran) }

  let(:relationship) do
    Relationship.new(
      veteran_file_number: veteran.file_number,
      participant_id: "1234",
      first_name: "BOB",
      last_name: "VANCE",
      relationship_type: "Spouse"
    )
  end

  context "#ui_hash" do
    subject { relationship.ui_hash }

    context "when there are no prior claims for that relationship" do
      it "returns a hash with a nil default_payee_code" do
        expect(subject).to include(
          participant_id: "1234",
          first_name: "BOB",
          last_name: "VANCE",
          relationship_type: "Spouse",
          default_payee_code: nil
        )
      end
    end

    context "when there are claims with that relationship" do
      let!(:recent_end_product_with) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "claim_id",
            claimant_first_name: relationship.first_name,
            claimant_last_name: relationship.last_name,
            payee_type_code: "10",
            claim_date: 5.days.ago
          }
        )
      end

      let!(:outdated_end_product) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "another_claim_id",
            claimant_first_name: relationship.first_name,
            claimant_last_name: relationship.last_name,
            payee_type_code: "11",
            claim_date: 10.days.ago
          }
        )
      end

      it "returns hash with the claimant's most recently used payee code" do
        expect(subject).to include(
          participant_id: "1234",
          first_name: "BOB",
          last_name: "VANCE",
          relationship_type: "Spouse",
          default_payee_code: "10"
        )
      end
    end
  end
end
