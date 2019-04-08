describe RampReview do
  let(:ramp_election) { create(:ramp_election) }

  context "#end_product_active?" do
    subject { ramp_election.end_product_active? }

    context "when the end_product_establishment can sync" do
      context "when the end product is inactive" do
        expect(subject).to be_false
      end

      context "when the end product is active" do
        expect(subject).to be_true
      end
    end

    context "when there are preexisting end products" do
      let(:completed_ramp_election_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: { status_type_code: "CLR" }
        )
      end
      context "all preexisting end products are inactive" do
        expect(subject).to be_false
      end

      context "one preexisting end product is active" do
        expect(subject).to be_true
      end
    end
  end
end
