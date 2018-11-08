describe Distribution do
  let(:css_id) { "BVARZIEMANN1" }
  let(:judge) { create(:user, css_id: css_id) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: css_id) }

  context "validations" do
    subject { Distribution.create(judge: user) }

    let(:user) { judge }

    it "validates when all's well" do
      expect(subject.valid?).to be(true)
    end

    context "when the user is not a judge in VACOOLS" do
      let(:user) { create(:user) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end

    context "when the judge has an unassigned legacy appeal" do
      let!(:legacy_appeal) { create(:case, bfcurloc: vacols_judge.slogid) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end

    context "when the judge has an unassigned AMA appeal" do
      let!(:task) { create(:ama_judge_task, assigned_to: judge) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end
  end

  context "#batch_size" do
    subject { Distribution.create(judge: judge).send(:batch_size) }

    it "is the number of attorneys times 5" do
      expect(subject).to eq(15)
    end

    context "when judge is not known" do
      let(:css_id) { "RANDO" }

      it "is equal to 10" do
        expect(subject).to eq(10)
      end
    end
  end

  context "#total_batch_size" do
    subject { Distribution.create(judge: judge).send(:total_batch_size) }

    it "is the total number of attorneys times 5" do
      expect(subject).to eq(45)
    end
  end
end
