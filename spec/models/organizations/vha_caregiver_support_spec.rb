# frozen_string_literal: true

describe VhaCaregiverSupport, :postgres do
  let(:vha_csp) do
    VhaCaregiverSupport.create(name: "VHA Caregiver Support Program", url: "vha-csp")
  end

  describe ".singleton" do
    it "VhaCaregiverSupport class has singleton class method defined
      for providing singleton-like behavior" do
      expect(VhaCaregiverSupport.respond_to?(:singleton)).to eq true
    end
  end

  describe ".create!" do
    it "organization that was created has expected name" do
      expect(vha_csp.name).to eq("VHA Caregiver Support Program")
    end

    it "organization that was created has expected url" do
      expect(vha_csp.url).to eq("vha-csp")
    end
  end

  describe ".queue_tabs" do
    it "returns the expected tabs for use in the VHA CSP organization's queue" do
      expect(vha_csp.queue_tabs).to match_array []
    end
  end

  describe ".can_receive_task?" do
    let(:appeal) { create(:appeal) }
    let(:task) { create(:task, appeal: appeal) }

    # This comes into play for any task with the "ASSIGN_TO_TEAM" task action
    it "returns false because VHA CSP office cannot have tasks manually assigned to them" do
      expect(vha_csp.can_receive_task?(task)).to eq(false)
    end
  end
end
