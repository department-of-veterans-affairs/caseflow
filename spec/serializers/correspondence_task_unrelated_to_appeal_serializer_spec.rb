# frozen_string_literal: true

RSpec.describe WorkQueue::CorrespondenceTaskUnrelatedToAppealSerializer do
  let(:user) { create(:user, css_id: "USER123") }
  let(:organization) { create(:organization, id: 21, name: "InboundOpsTeam") }
  let(:correspondence) { create(:correspondence, id: 42) }
  let(:current_user) { user }

  before { RequestStore[:current_user] = current_user }

  let(:task) do
    ReturnToInboundOpsTask.create!(
      id: 4449,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_at: Time.zone.parse("2024-10-28 20:59:27"),
      assigned_by: user,
      assigned_to: organization,
      assigned_to_type: "Organization",
      status: Constants.TASK_STATUSES.assigned,
      closed_at: Time.zone.now
    )
  end

  subject(:serialized) { described_class.new(task).serializable_hash }

  describe "assigned_on attribute" do
    it "formats assigned_at as MM/DD/YYYY" do
      expect(serialized[:data][:attributes][:assignedOn]).to eq("10/28/2024")
    end
  end

  describe "assigned_to attribute" do
    context "when assigned_to_type is Organization" do
      it "returns the organization's name" do
        expect(serialized[:data][:attributes][:assignedTo]).to eq("InboundOpsTeam")
      end
    end

    context "when assigned_to_type is User" do
      before { task.update!(assigned_to: user, assigned_to_type: "User") }

      it "returns the user's css_id" do
        expect(serialized[:data][:attributes][:assignedTo]).to eq("USER123")
      end
    end
  end

  describe "type attribute" do
    it "returns assigned_to_type" do
      expect(serialized[:data][:attributes][:type]).to eq("Organization")
    end
  end

  describe "unique_id attribute" do
    it "returns the task id" do
      expect(serialized[:data][:attributes][:uniqueId]).to eq(4449)
    end
  end

  describe "available_actions attribute" do
    it "returns the result of available_actions_unwrapper" do
      allow(task).to receive(:available_actions_unwrapper).with(current_user).and_return(["action1"])

      expect(serialized[:data][:attributes][:availableActions]).to eq(["action1"])
    end
  end

  describe "assigned_by attribute" do
    it "returns the assigned_by user's css_id when task is ReturnToInboundOpsTask" do
      expect(serialized[:data][:attributes][:assignedBy]).to eq("USER123")
    end
  end

  describe "reassign_users attribute" do
    it "returns the result of reassign_users" do
      allow(task).to receive(:reassign_users).and_return(["user1"])
      expect(serialized[:data][:attributes][:reassignUsers]).to eq(["user1"])
    end
  end

  describe "assigned_to_org attribute" do
    it "returns true if assigned_to is an Organization" do
      expect(serialized[:data][:attributes][:assignedToOrg]).to be true
    end
  end

  describe "organizations attribute" do
    it "returns a list of organizations with labels and values" do
      org1 = create(:organization, name: "Org1", id: 101)
      org2 = create(:organization, name: "Org2", id: 102)
      allow(task).to receive(:reassign_organizations).and_return([org1, org2])

      expect(serialized[:data][:attributes][:organizations]).to eq(
        [
          { label: "Org1", value: 101 },
          { label: "Org2", value: 102 }
        ]
      )
    end
  end
end
