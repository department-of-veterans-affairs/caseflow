require 'rails_helper'

RSpec.describe HearingsSupervisor, type: :model do
  describe ".perform" do
    it "is named correctly" do
      expect(described_class.singleton).to have_attributes(name: "Hearings Supervisor")
    end

    it "will only have one HearingsSupervisor no matter how many times it is run" do
      described_class.singleton
      described_class.singleton
      expect(Organization.where(name: "Hearings Supervisor").count).to eq(1)
    end

    it "will have the correct url name" do
      expect(described_class.singleton).to have_attributes(url: "hearings-supervisors")
    end
  end

  describe "can_receive_task?" do
    #this will be more filled in when the method gets written
    let(:task) { create(:task) }
    let(:hearings_supervisor) { described_class.new}

    it "will always return false" do
      expect(hearings_supervisor.can_receive_task?(task)).to eq(false)
    end
  end
end
