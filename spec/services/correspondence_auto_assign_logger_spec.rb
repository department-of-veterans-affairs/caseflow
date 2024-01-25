# frozen_string_literal: true

describe CorrespondenceAutoAssignLogger do
  subject(:instance) { described_class.new(current_user) }
  let(:veteran) { create(:veteran) }
  let(:current_user) { create(:user) }

  let!(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, uuid: SecureRandom.uuid) }

  describe "#begin_logging" do
    it "creates a BatchAutoAssignmentAttempt" do
      expect do
        instance.begin_logging
      end.to change(BatchAutoAssignmentAttempt, :count)
    end
  end

  describe "#end_logging" do
    it "updates a BatchAutoAssignmentAttempt with status" do
      instance.begin_logging
      expect do
        instance.end_logging(BatchAutoAssignmentAttempt::STATUS_STARTED)
      end.to change(instance.batch_assignment.status).to(BatchAutoAssignmentAttempt::STATUS_STARTED)
    end
  end

  describe "#log_single_attempt" do
    it "creates an IndividualAutoAssignmentAttempt" do
      expect do
        instance.log_single_attempt(user_id: current_user.id, correspondence_id: correspondence.id)
      end.to change(IndividualAutoAssignmentAttempt, :count)
    end
  end

  describe "#record_failure" do
    it "increase failed attempts count" do
      expect do
        instance.log_single_attempt(user_id: current_user.id, correspondence_id: correspondence.id)
        instance.record_failure
      end.to change { instance.failed_attempts_count }.by(1)
        .and change { instance.failed_assignments.length }.by(1)
        .and expect { instance.current_assignment }.to(nil)
    end
  end

  describe "#record_success" do
    it "increase failed attempts count" do
      expect do
        instance.log_single_attempt(user_id: current_user.id, correspondence_id: correspondence.id)
        instance.record_success
      end.to change { instance.successful_assignments }.by(1)
        .and change { instance.current_assignment }.to(nil)
    end
  end
end
