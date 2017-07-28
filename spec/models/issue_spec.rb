describe Issue do
  let(:disposition) { :allowed }
  let(:program) { :compensation }
  let(:category) { :elbow }
  let(:type) { { name: :service_connection, label: "Service Connection" } }

  let(:issue) do
    Generators::Issue.build(disposition: disposition,
                            program: program,
                            type: type,
                            category: category)
  end

  context ".load_from_vacols" do
    subject { Issue.load_from_vacols(issue_hash) }
    let(:issue_hash) do
      # NOTE: This is the exact structure pulled from VACOLS
      # please do not touch this!
      { "isskey" => "12345678",
        "issseq" => 1,
        "issdc" => "3",
        "issdesc" => nil,
        "issprog" => "02",
        "isscode" => "15",
        "isslev1" => "02",
        "isslev2" => "03",
        "isslev3" => "04",
        "issprog_label" => "Compensation",
        "isscode_label" => "1151 Eligibility",
        "isslev1_label" => "Other",
        "isslev2_label" => "Left knee",
        "isslev3_label" => "Right knee" }
    end

    it "assigns values properly" do
      expect(subject.levels).to eq(["Other", "Left knee", "Right knee"])
      expect(subject.program).to eq(:compensation)
      expect(subject.program_description).to eq("02 - Compensation")
      expect(subject.type).to eq(
        name: :service_connection,
        label: "1151 Eligibility"
      )
      expect(subject.description).to eq(["15 - 1151 Eligibility", "02 - Other", "03 - Left knee", "04 - Right knee"])
      expect(subject.disposition).to eq(:remanded)
    end
  end

  context ".parse_levels_from_vacols" do
    subject { Issue.parse_levels_from_vacols(levels_hash) }

    context "when all three levels are present in VACOLS" do
      let(:levels_hash) do
        { "isslev1" => "02",
          "isslev2" => "0304",
          "isslev3" => "0404",
          "isslev1_label" => "Other",
          "isslev2_label" => "Right elbow",
          "isslev3_label" => "Right shoulder" }
      end

      it "returns level descriptions in order" do
        expect(subject).to eq(["Other", "Right elbow", "Right shoulder"])
      end
    end

    context "when there are less than three levels returned from VACOLS" do
      let(:levels_hash) do
        { "isslev1" => "02",
          "isslev1_label" => "Other" }
      end

      it "returns the amount of issue levels present" do
        expect(subject).to eq(["Other"])
      end
    end
  end

  context "#allowed?" do
    subject { issue.allowed? }

    context "when disposition is allowed" do
      let(:disposition) { :allowed }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not allowed" do
      let(:disposition) { :remanded }

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
      let(:type) { { name: :increase_rating, label: "Increase Rating" } }

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
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end
    end

    context "when new material" do
      let(:category) { :new_material }

      context "when allowed disposition" do
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end

      context "when non-allowed disposition" do
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end
    end

    context "when non-allowed disposition" do
      let(:disposition) { :remanded }

      it "returns false" do
        expect(issue.allowed?).to be_falsey
        expect(subject).to be_falsey
      end
    end
  end
end
