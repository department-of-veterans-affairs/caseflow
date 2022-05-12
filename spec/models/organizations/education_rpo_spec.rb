# frozen_string_literal: true

describe EducationRpo, :postgres do
  let(:education_rpo) do
    EducationRpo.create!(name: "Regional Processing Office", url: "Regional Processing Office")
  end

  describe ".create!" do
    it "creates a Regional Processing Office" do
      expect(education_rpo.name).to eq("Regional Processing Office")
    end
  end

  describe ".can_receive_task?" do
    let(:appeal) { create(:appeal) }
    let(:doc_task) { create(:education_document_search_task, appeal: appeal) }

    it "returns false because program offices should not have edu document search tasks assigned to them" do
      expect(education_rpo.can_receive_task?(doc_task)).to eq(false)
    end
  end
end
