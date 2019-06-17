# frozen_string_literal: true

describe PrivateBar do
  describe ".create!" do
    let(:private_bar) { PrivateBar.create!(name: "Caseflow Law Group", url: "caseflow-law") }
    let(:appeal) { FactoryBot.create(:appeal) }

    before do
      allow(appeal).to receive(:representatives).and_return(PrivateBar.where(id: private_bar.id))
    end

    it "creates a representative that does not write IHPs for appeals they represent" do
      expect(appeal.representatives.include?(private_bar)).to eq(true)
      expect(private_bar.should_write_ihp?(appeal)).to eq(false)
    end
  end
end
