describe Issue do
  let(:disposition) { :allowed }
  let(:program) { :compensation }
  let(:category) { :elbow }
  let(:type) { :service_connection }

  let(:issue) do
    Generators::Issue.build(disposition: disposition,
                            program: program,
                            type: type,
                            category: category)
  end

  context "#allowed?" do
    subject { issue.allowed? }

    context "when disposition is allowed" do
      let(:disposition) { :allowed }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not allowed" do
      let(:disposition) { :remand }

      it { is_expected.to be_falsey }
    end
  end

  context "#new_material?" do
    subject { issue.new_material? }

    context "when program is not compensation" do
      let(:program) { :some_other_prog }

      it { is_expected.to be_falsey }
    end

    context "when category is not new_material" do
      let(:category) { :elbow }

      it { is_expected.to be_falsey }
    end

    context "when type is not service_connection" do
      let(:type) { :increase_rating }

      it { is_expected.to be_falsey }
    end

    context "when category is new_material, type is service_connection, program is compensation" do
      let(:category) { :new_material }

      it { is_expected.to be_truthy }
    end
  end

  context "#not_new_material?" do
    subject { issue.non_new_material? }

    it "is the opposite of new_material?" do
      expect(subject).to eq(!issue.new_material?)
    end
  end

  context "#non_new_material_allowed?" do
    subject { issue.non_new_material_allowed? }

    context "when non_new_material" do
      it { is_expected.to be_truthy }

      context "when allowed disposition" do
        let(:disposition) { :allowed }
        it { is_expected.to be_truthy }
      end

      context "when non-allowed disposition" do
        let(:disposition) { :remand }
        it { is_expected.to be_falsey }
      end
    end

    context "when new material" do
      let(:category) { :new_material }

      context "when allowed disposition" do
        let(:disposition) { :remand }
        it { is_expected.to be_falsey }
      end

      context "when non-allowed disposition" do
        let(:disposition) { :remand }
        it { is_expected.to be_falsey }
      end
    end

    context "when non-allowed disposition" do
      let(:disposition) { :remand }

      it "returns false" do
        expect(issue.allowed?).to be_falsey
        expect(subject).to be_falsey
      end
    end
  end
end
