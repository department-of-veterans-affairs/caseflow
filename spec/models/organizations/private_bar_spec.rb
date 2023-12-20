# frozen_string_literal: true

describe PrivateBar, :postgres do
  let(:private_bar) { PrivateBar.create!(name: "Caseflow Law Group", url: "caseflow-law") }

  describe ".create!" do
    let(:appeal) { create(:appeal) }

    before do
      allow(appeal).to receive(:representatives).and_return(PrivateBar.where(id: private_bar.id))
    end

    it "creates a representative that does not write IHPs for appeals they represent" do
      expect(appeal.representatives.include?(private_bar)).to eq(true)
      expect(private_bar.should_write_ihp?(appeal)).to eq(false)
    end
  end

  describe ".queue_tabs" do
    it "only returns a single tab with tracking tasks" do
      tabs = private_bar.queue_tabs
      expect(tabs.length).to eq(1)
      expect(tabs.first).to be_a(OrganizationTrackingTasksTab)
    end
  end
end
