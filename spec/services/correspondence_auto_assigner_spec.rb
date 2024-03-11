# frozen_string_literal: true

describe CorrespondenceAutoAssigner do
  subject(:described) do
    described_class.new(
      current_user_id: current_user.id,
      batch_auto_assignment_attempt_id: batch_auto_assignment_attempt.id
    )
  end

  let(:batch_auto_assignment_attempt) { create(:batch_auto_assignment_attempt, user_id: current_user.id) }
  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:user) }

  let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }

  let(:mock_assignable_user_finder) { instance_double(AutoAssignableUserFinder) }

  before do
    allow(AutoAssignableUserFinder).to receive(:new).and_return(mock_assignable_user_finder)
  end

  describe "#perform" do
    context "when assignable users exist" do
      let(:intake_user) { create(:intake_user) }
      let!(:org_user) { create(:organizations_user, organization: InboundOpsTeam.singleton, user: intake_user) }

      before do
        expect(mock_assignable_user_finder).to receive(:assignable_users_exist?).and_return(true)
        expect(mock_assignable_user_finder).to receive(:get_first_assignable_user).and_return(intake_user)
      end

      it "assigns review package tasks to assignable users" do
        described.perform

        task = ReviewPackageTask.last
        expect(task.assigned_to).to eq(intake_user)
        expect(task.status).to eq("assigned")
      end
    end
  end
end
