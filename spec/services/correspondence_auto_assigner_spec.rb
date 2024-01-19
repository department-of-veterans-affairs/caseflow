# frozen_string_literal: true

describe CorrespondenceAutoAssigner do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:intake_user) }

  let!(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let!(:unassigned_task) { create(:review_package_task, appeal: correspondence, status: "unassigned") }

  describe "#do_auto_assignment" do
    it "successfully creates a ReviewPackageTask and updates the existing task" do
      expect do
        described.do_auto_assignment(current_user_id: current_user.id)
      end.to change(ReviewPackageTask, :count)

      expect(unassigned_task.assigned_to).to eq(InboundOpsTeam.singleton)
      expect(unassigned_task.status).to eq(:on_hold)
    end
  end
end
