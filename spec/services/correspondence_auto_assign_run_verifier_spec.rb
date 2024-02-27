# frozen_string_literal: true

describe CorrespondenceAutoAssignRunVerifier do
  subject(:described) { described_class.new }

  let(:current_user) { create(:user) }

  describe "#can_run_auto_assign?" do
    let!(:valid_batch) do
      create(
        :batch_auto_assignment_attempt,
        user: current_user,
        completed_at: (described.min_minutes_elapsed_batch_attempt + 1).minutes.ago
      )
    end

    let!(:valid_batch_recent) do
      create(
        :batch_auto_assignment_attempt,
        user: current_user,
        status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed,
        completed_at: (described.min_minutes_elapsed_batch_attempt - 1).minutes.ago
      )
    end

    context "when true" do
      context "with completed IndividualAutoAssignmentAttempt" do
        let!(:individual) do
          create(
            :individual_auto_assignment_attempt,
            batch_auto_assignment_attempt: valid_batch,
            completed_at: (described.min_minutes_elapsed_individual_attempt + 1).minutes.ago
          )
        end

        it "returns true" do
          expect(
            described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: valid_batch.id)
          ).to eq(true)
        end
      end

      context "with completed BatchAutoAssignmentAttempt" do
        it "returns true" do
          expect(
            described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: valid_batch.id)
          ).to eq(true)
        end
      end
    end

    context "when false" do
      context "with feature toggles enabled" do
        before do
          FeatureToggle.enable!(:auto_assign_banner_failure)
        end

        it "returns false" do
          expect(
            described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: valid_batch.id)
          ).to eq(false)
        end
      end

      context "with invalid current_user_id" do
        it "returns false" do
          expect(
            described.can_run_auto_assign?(current_user_id: 0, batch_auto_assignment_attempt_id: valid_batch.id)
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
          let!(:invalid_individual) do
            create(
              :individual_auto_assignment_attempt,
              batch_auto_assignment_attempt: valid_batch,
              completed_at: 1.minutes.ago
            )
          end

          before do
            batch_stubbed = class_double(BatchAutoAssignmentAttempt).as_stubbed_const(:transfer_nested_constants => true)
            expect(batch_stubbed).to receive(:find_by).with(user: current_user, id: valid_batch.id).and_return(valid_batch)
            expect(batch_stubbed).not_to receive(:where)
          end

          it "returns false" do
            expect(
              described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: valid_batch.id)
            ).to eq(false)
          end
        end

        context "when the latest BatchAutoAssignmentAttempt occurred too recently" do
          let!(:recent_batch) do
            create(
              :batch_auto_assignment_attempt,
              user: current_user,
              completed_at: (described.min_minutes_elapsed_batch_attempt - 1).minutes.ago
            )
          end

          it "returns false" do
            expect(
              described.can_run_auto_assign?(current_user_id: current_user.id, batch_auto_assignment_attempt_id: recent_batch.id)
            ).to eq(false)
          end
        end
      end
    end
  end
end
