# frozen_string_literal: true

describe EducationEmo, :postgres do
  let(:education_emo) { EducationEmo.create(name: "Executive Management Office", url: "edu-emo") }

  describe ".create!" do
    it "creates the Education EMO" do
      expect(education_emo.name).to eq("Executive Management Office")
    end
  end

  describe ".can_receive_task?" do
    let(:appeal) { create(:appeal) }
    let(:assess_doc_task) { create(:education_assess_documentation_task, appeal: appeal, assigned_to: education_emo) }

    it "returns false because EMO should not have education assess documentation tasks assigned to them" do
      expect(education_emo.can_receive_task?(assess_doc_task)).to eq(false)
    end
  end
end
