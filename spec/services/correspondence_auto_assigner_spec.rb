# frozen_string_literal: true

describe CorrespondenceAutoAssigner do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:user) }

  let!(:batch) { create(:batch_auto_assignment_attempt, user: current_user) }

  let(:mock_assignable_user_finder) { instance_double(AutoAssignableUserFinder) }
  let(:mock_run_verifier) { instance_double(CorrespondenceAutoAssignRunVerifier) }

  before do
    allow(AutoAssignableUserFinder).to receive(:new).and_return(mock_assignable_user_finder)
    allow(CorrespondenceAutoAssignRunVerifier).to receive(:new).and_return(mock_run_verifier)
  end

  describe "#perform" do
    context "when a run is permitted" do
      before do
        expect(mock_run_verifier).to receive(:can_run_auto_assign?).and_return(true)
        expect(mock_run_verifier).to receive(:verified_batch).and_return(batch)
        expect(mock_run_verifier).to receive(:verified_user).and_return(current_user)
      end

      context "with unassigned ReviewPackageTasks" do
        let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }

        context "when assignable users exist" do
          let(:intake_user) { create(:intake_user) }
          let!(:org_user) { create(:organizations_user, organization: InboundOpsTeam.singleton, user: intake_user) }

          before do
            expect(mock_assignable_user_finder).to receive(:assignable_users_exist?).and_return(true)
            expect(mock_assignable_user_finder).to receive(:get_first_assignable_user).and_return(intake_user)
          end

          it "assigns review package tasks to assignable users" do
            described.perform(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch.id
            )

            task = ReviewPackageTask.last
            expect(task.assigned_to).to eq(intake_user)
            expect(task.status).to eq("assigned")
          end
        end

        context "when assignable users do NOT exist" do
          before do
            expect(mock_assignable_user_finder).to receive(:assignable_users_exist?).and_return(false)
          end

          it "updates the BatchAutoAssignmentAttempt with a capacity error message" do
            described.perform(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch.id
            )

            reloaded = batch.reload
            expect(reloaded.status).to eq("error")
            expect(reloaded.error_info["message"]).to match(/maximum capacity/)
          end
        end
      end

      context "when unassigned ReviewPackageTasks do NOT exist" do
        it "updates the BatchAutoAssignmentAttempt with a no correspondences error message" do
          described.perform(
            current_user_id: current_user.id,
            batch_auto_assignment_attempt_id: batch.id
          )

          reloaded = batch.reload
          expect(reloaded.status).to eq("error")
          expect(reloaded.error_info["message"]).to match(/no correspondences/)
        end
      end
    end

    context "when a run is NOT permitted" do
      before do
        expect(mock_run_verifier).to receive(:can_run_auto_assign?).and_return(false)
        expect(mock_run_verifier).to receive(:err_msg).twice.and_return("Test error")
      end

      it "raises an error" do
        expect do
          described.perform(
            current_user_id: current_user.id,
            batch_auto_assignment_attempt_id: batch.id
          )
        end.to raise_error(RuntimeError, "Test error")
      end
    end
  end
end
