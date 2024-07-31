# frozen_string_literal: true

describe CorrespondenceAutoAssigner do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:user) }

  let!(:batch) { create(:batch_auto_assignment_attempt, user: current_user) }

  let(:mock_assignable_user_finder) { instance_double(AutoAssignableUserFinder) }
  let(:mock_run_verifier) { instance_double(CorrespondenceAutoAssignRunVerifier) }

  before do
    FeatureToggle.disable!(:auto_assign_banner_failure)
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
        context "when assignable users exist" do
          let(:intake_user) { create(:intake_user) }
          let!(:org_user) { create(:organizations_user, organization: InboundOpsTeam.singleton, user: intake_user) }

          before do
            expect(mock_assignable_user_finder).to receive(:assignable_users_exist?).and_return(true)
            allow(mock_assignable_user_finder).to receive(:unassignable_reasons).and_return(["User is at max capacity"])
          end

          it "assigns review package tasks to assignable users" do
            correspondence = create(:correspondence, veteran_id: veteran.id, va_date_of_receipt: 1.day.ago)
            expect(mock_assignable_user_finder).to receive(:get_first_assignable_user).and_return(intake_user)

            described.perform(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch.id
            )

            expect(correspondence.review_package_task.assigned_to).to eq(intake_user)
            expect(correspondence.review_package_task.status).to eq("assigned")
          end

          context "with varying va_date_of_receipt values" do
            let!(:new_correspondence) { create(:correspondence, veteran_id: veteran.id, va_date_of_receipt: 1.day.ago) }
            let!(:old_correspondence) do
              create(:correspondence, veteran_id: veteran.id, va_date_of_receipt: 1.year.ago)
            end

            let(:mock_run_logger) { instance_double(CorrespondenceAutoAssignLogger, begin: nil, end: nil) }

            before do
              allow(CorrespondenceAutoAssignLogger).to receive(:new).and_return(mock_run_logger)
            end

            it "assigns the correspondence with the oldest va_date_of_receipt first" do
              # mock successful assignment
              expect(mock_assignable_user_finder).to receive(:get_first_assignable_user).and_return(intake_user)
              expect(mock_run_logger).to receive(:assigned)
                .with(
                  task: old_correspondence.review_package_task,
                  started_at: instance_of(ActiveSupport::TimeWithZone),
                  assigned_to: intake_user
                )

              # mock failed assignment (i.e no user has capacity)
              expect(mock_assignable_user_finder).to receive(:get_first_assignable_user).and_return(nil)
              expect(mock_run_logger).to receive(:no_eligible_assignees)
                .with(
                  task: new_correspondence.review_package_task,
                  started_at: instance_of(ActiveSupport::TimeWithZone),
                  unassignable_reason: "User is at max capacity"
                )

              described.perform(
                current_user_id: current_user.id,
                batch_auto_assignment_attempt_id: batch.id
              )

              expect(old_correspondence.review_package_task.assigned_to).to eq(intake_user)
              expect(old_correspondence.review_package_task.status).to eq("assigned")

              expect(new_correspondence.review_package_task.assigned_to).to eq(InboundOpsTeam.singleton)
              expect(new_correspondence.review_package_task.status).to eq("unassigned")
            end
          end
        end

        context "when assignable users do NOT exist" do
          let!(:correspondence) { create(:correspondence, veteran_id: veteran.id, va_date_of_receipt: 1.day.ago) }

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
