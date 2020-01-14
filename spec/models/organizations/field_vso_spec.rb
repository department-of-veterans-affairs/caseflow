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
end
