# frozen_string_literal: true

describe FieldVso, :postgres do
  let(:vso) { FieldVso.create!(name: "VSO name here", url: "vso-name-here") }

  describe ".create!" do
    it "creates an associated VsoConfig object with no ihp_dockets when it is created" do
      expect(vso.vso_config.ihp_dockets).to eq([])
    end
  end

  describe ".queue_tabs" do
    it "only returns a single tab with tracking tasks" do
      tabs = vso.queue_tabs
      expect(tabs.length).to eq(1)
      expect(tabs.first).to be_a(OrganizationTrackingTasksTab)
    end
  end

  describe "should_write_ihp?" do
    let(:appeal) { create(:appeal) }

    before do
      allow(appeal).to receive(:representatives).and_return(FieldVso.where(id: vso.id))
    end

    it "a field vso does not write IHPs for appeals they represent" do
      expect(appeal.representatives.include?(vso)).to eq(true)
      expect(vso.should_write_ihp?(appeal)).to eq(false)
    end
  end
end
