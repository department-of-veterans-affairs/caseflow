# frozen_string_literal: true

describe AutoAssignCorrespondenceJob, :postgres do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform_later" do
    it "enqueues a job" do
      expect do
        described_class.perform_later(
          current_user_id: 1,
          batch_auto_assignment_attempt_id: 1
        )
      end.to have_enqueued_job
    end
  end
end
