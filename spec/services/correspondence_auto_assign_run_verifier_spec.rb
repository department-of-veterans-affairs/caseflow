# frozen_string_literal: true

describe CorrespondenceAutoAssignRunVerifier do
  subject(:described) { described_class.new }

  let(:current_user) { create(:user) }
  let(:min_minutes_elapsed_batch_attempt) do
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.timing.min_minutes_elapsed_batch_attempt
  end
  let(:min_minutes_elapsed_individual_attempt) do
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.timing.min_minutes_elapsed_individual_attempt
  end

  let(:batch_for_verification) do
    create(
      :batch_auto_assignment_attempt,
      user: current_user
    )
  end

  describe "#can_run_auto_assign?" do
    context "when true" do
      context "when an IndividualAutoAssignmentAttempt exists" do
        let!(:batch) do
          create(
            :batch_auto_assignment_attempt,
            user: current_user,
            created_at: (min_minutes_elapsed_batch_attempt + 1).minutes.ago
          )
        end

        let!(:individual) do
          create(
            :individual_auto_assignment_attempt,
            batch_auto_assignment_attempt: batch,
            created_at: (min_minutes_elapsed_individual_attempt + 1).minutes.ago
          )
        end

        it "returns true" do
          expect(
            described.can_run_auto_assign?(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch_for_verification.id
            )
          ).to eq(true)
        end
      end

      context "when a completed BatchAutoAssignmentAttempt exists" do
        let!(:completed_batch) do
          create(
            :batch_auto_assignment_attempt,
            user: current_user,
            created_at: (min_minutes_elapsed_batch_attempt - 1).minutes.ago,
            status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed
          )
        end

        it "returns true" do
          expect(
            described.can_run_auto_assign?(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch_for_verification.id
            )
          ).to eq(true)
        end
      end
    end

    context "when false" do
      context "with feature toggles enabled" do
        let(:batch) { create(:batch_auto_assignment_attempt) }

        before do
          FeatureToggle.enable!(:auto_assign_banner_failure)
        end

        it "returns false" do
          expect(
            described.can_run_auto_assign?(
              current_user_id: current_user.id,
              batch_auto_assignment_attempt_id: batch.id
            )
          ).to eq(false)
        end
      end

      context "with invalid current_user_id" do
        let(:batch) { create(:batch_auto_assignment_attempt) }

        it "returns false" do
          expect(
            described.can_run_auto_assign?(current_user_id: 0, batch_auto_assignment_attempt_id: batch.id)
          ).to eq(false)
        end
      end

      context "with invalid batch_auto_assignment_attempt_id" do
        it "returns false" do
          expect(
            described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: 0)
          ).to eq(false)
        end
      end

      context "when checking for concurrent runs" do
        context "when the latest IndividualAutoAssignmentAttempt occurred too recently" do
          let!(:batch) do
            create(
              :batch_auto_assignment_attempt,
              user: current_user,
              created_at: (min_minutes_elapsed_batch_attempt + 1).minutes.ago
            )
          end
          let!(:invalid_individual) do
            create(
              :individual_auto_assignment_attempt,
              batch_auto_assignment_attempt: batch,
              created_at: 1.minute.ago
            )
          end

          before do
            # Ensure that we don't hit this code block
            batch_stubbed = class_double(BatchAutoAssignmentAttempt)
              .as_stubbed_const(transfer_nested_constants: true)
            expect(batch_stubbed).to receive(:find_by)
              .with(user: current_user, id: batch.id).and_return(batch)
            expect(batch_stubbed).not_to receive(:where)
          end

          it "returns false" do
            expect(
              described.can_run_auto_assign?(
                current_user_id: current_user.id,
                batch_auto_assignment_attempt_id: batch.id
              )
            ).to eq(false)
          end
        end

        context "when the latest BatchAutoAssignmentAttempt occurred too recently" do
          let(:batch) { create(:batch_auto_assignment_attempt) }
          let!(:recent_batch) do
            create(
              :batch_auto_assignment_attempt,
              user: current_user,
              created_at: (min_minutes_elapsed_batch_attempt - 1).minutes.ago
            )
          end

          it "returns false" do
            expect(
              described.can_run_auto_assign?(
                current_user_id: current_user.id,
                batch_auto_assignment_attempt_id: batch.id
              )
            ).to eq(false)
          end
        end
      end
    end
  end
end
