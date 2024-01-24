# frozen_string_literal: true

describe CorrespondenceAutoAssigner do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:intake_user) }

  let!(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, uuid: SecureRandom.uuid) }

  let(:mock_permission_checker) { instance_double(OrganizationUserPermissionChecker, can?: true) }

    before do
      allow(OrganizationUserPermissionChecker).to receive(:new).and_return(mock_permission_checker)
    end

  describe "#do_auto_assignment" do
    it "successfully creates a ReviewPackageTask and updates the existing task" do
      expect do
        described.do_auto_assignment(current_user_id: current_user.id)
      end.to change(ReviewPackageTask, :count)

      created = ReviewPackageTask.last
      expect(created.assigned_to).to eq(InboundOpsTeam.singleton)
      expect(created.status).to eq("assigned")
    end
  end
end
