describe Distribution do
  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

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
end
