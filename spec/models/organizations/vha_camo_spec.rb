# frozen_string_literal: true

describe VhaCamo, :postgres do
  let(:vha_camo) { VhaCamo.create(name: "VHA CAMO", url: "vha-camo") }

  describe ".create!" do
    it "creates the Vha Camo" do
      expect(vha_camo.name).to eq("VHA CAMO")
    end
  end

  describe ".can_receive_task?" do
    let(:appeal) { create(:appeal) }
    let(:vha_assess_doc_task) { create(:assess_documentation_task, appeal: appeal) }

    it "returns false because Vha Camo should not have assess documentation tasks assigned to them" do
      expect(vha_camo.can_receive_task?(vha_assess_doc_task)).to eq(false)
    end
  end
end
