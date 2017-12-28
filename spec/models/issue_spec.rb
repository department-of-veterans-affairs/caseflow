describe Issue do
  let(:disposition) { :allowed }
  let(:codes) { ["02", "15", "03", "5252"] }
  let(:labels) { ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }

  let(:issue) do
    Generators::Issue.build(disposition: disposition,
                            codes: codes,
                            labels: labels)
  end

  context ".load_from_vacols" do
    subject { Issue.load_from_vacols(issue_hash) }
    let(:issue_hash) do
      # NOTE: This is the exact structure pulled from VACOLS
      # please do not touch this!
      { "isskey" => "12345678",
        "issseq" => 1,
        "issdc" => "3",
        "issdcls" => 3.days.ago,
        "issdesc" => "low back condition",
        "issprog" => "02",
        "isscode" => "15",
        "isslev1" => "03",
        "isslev2" => "5252",
        "isslev3" => nil,
        "issprog_label" => "Compensation",
        "isscode_label" => "Service connection",
        "isslev1_label" => "All Others",
        "isslev2_label" => "Thigh, limitation of flexion of",
        "isslev3_label" => nil }
    end

    it "assigns values properly" do
      expect(subject.codes).to eq(codes)
      expect(subject.labels).to eq(labels)
      expect(subject.note).to eq("low back condition")
      expect(subject.disposition).to eq(:remanded)
      expect(subject.close_date).to eq(AppealRepository.normalize_vacols_date(3.days.ago))
    end

    context "when issues are loaded without label joins" do
      let(:issue_hash) do
        # NOTE: This is the exact structure pulled from VACOLS
        # please do not touch this!
        { "isskey" => "12345678",
          "issseq" => 1,
          "issdc" => "3",
          "issdcls" => 3.days.ago,
          "issdesc" => "low back condition",
          "issprog" => "02",
          "isscode" => "15",
          "isslev1" => "02",
          "isslev2" => "03",
          "isslev3" => "04"
        }
      end

      it "raise exceptions for unloaded attributes" do
        expect(subject.note).to eq("low back condition")
        expect { subject.labels }.to raise_exception(Caseflow::Error::AttributeNotLoaded)
        expect { subject.description }.to raise_exception(Caseflow::Error::AttributeNotLoaded)
      end
    end
  end

  context "#program" do
    subject { issue.program }

    context "when the program is known" do
      it { is_expected.to eq(:compensation) }
    end

    context "when the program is not known" do
      let(:codes) { ["99", "99"] }
      it { is_expected.to be_nil }
    end
  end

  context "#type" do
    subject { issue.type }
    it { is_expected.to eq("Service connection") }
  end

  context "#program_description" do
    subject { issue.program_description }
    it { is_expected.to eq("02 - Compensation") }
  end

  context "#description" do
    subject { issue.description }
    it "returns an array for each description line" do
      is_expected.to eq([
        "15 - Service connection",
        "03 - All Others",
        "5252 - Thigh, limitation of flexion of"
      ])
    end
  end

  context "#levels" do
    subject { issue.levels }
    it { is_expected.to eq(["All Others", "Thigh, limitation of flexion of"]) }

    context "when there are no levels" do
      let(:labels) { ["Building maintenance", "Door won't open"] }
      it { is_expected.to eq([]) }
    end
  end

  context "#category" do
    subject { issue.category }
    it { is_expected.to eq("02-15") }
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

  context "#remanded?" do
    subject { issue.remanded? }

    context "when disposition is remanded" do
      let(:disposition) { :remanded }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not remanded" do
      let(:disposition) { :allowed }

      it { is_expected.to be_falsey }
    end
  end

  context "#merged?" do
    subject { issue.merged? }

    context "when disposition is merged" do
      let(:disposition) { :merged }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not merged" do
      let(:disposition) { :allowed }

      it { is_expected.to be_falsey }
    end
  end

  context "#new_material?" do
    subject { issue.new_material? }

    context "when not new and material" do
      it { is_expected.to be_falsey }
    end

    context "when new and material" do
      let(:codes) { ["02", "15", "04", "5252"] }

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
      let(:codes) { ["02", "15", "04", "5252"] }

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
