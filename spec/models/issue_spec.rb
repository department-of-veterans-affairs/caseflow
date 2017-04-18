describe Issue do
  let(:disposition) { "Allowed" }
  let(:new_material) { false }
  let(:issue) { { disposition: disposition, new_material: new_material } }
  end

  context "#allowed?" do
    subject { issue.allowed? }

    it { is_expected.to be_truthy }
  end

  context "#non_new_material_allowed?" do
    subject { issue.non_new_material_allowed? }

    it "returns true" do
      expect(new_material).to be_falsey
      expect(issue.allowed?).to be_truthy
      expect(subject).to be_truthy
    end

    context "when new material" do
      let(:new_material) { true }

      it "returns false" do
        expect(issue.allowed?).to be_truthy
        expect(subject).to be_falsey
      end
    end

    context "when non-allowed disposition" do
      let(:disposition) { "Remand" }

      it "returns false" do
        expect(issue.allowed?).to be_falsey
        expect(subject).to be_falsey
      end
    end
  end
end
