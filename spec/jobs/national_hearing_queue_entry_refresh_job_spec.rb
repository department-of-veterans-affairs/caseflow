# frozen_string_literal: true

describe NationalHearingQueueEntryRefreshJob, :postgres do
  include ActiveJob::TestHelper
  describe "#perform" do
    context "when it follows the happy path" do
      it "completes the national hearing queue refresh without raising any errors" do
        expect do
          perform_enqueued_jobs { NationalHearingQueueEntryRefreshJob.perform_later }
        end.not_to raise_error
      end
    end

    context "when the queue refresh is expecting to timeout" do
      # allow(object).to receive(:method).and_return(value)
      let(:job) { NationalHearingQueueEntryRefreshJob.new }
      before(:each) do
        allow(NationalHearingQueueEntry).to receive(:refresh).and_raise(ActiveRecord::StatementTimeout)
      end

      it "doesn't raise any errors" do
        expect do
          perform_enqueued_jobs { NationalHearingQueueEntryRefreshJob.perform_later }
        end.not_to raise_error
      end

      it "ensures perform is recursively ran" do
        expect(job).to receive(:perform).exactly(2).times.and_call_original
        job.perform
      end

      it "calls timeout_set to change the timeout value and calls perform2" do
        expect(job).to receive(:timeout_set).exactly(2).times
        job.perform
      end

      it "logs the error" do
        expect(job).to receive(:log_error)
        job.perform
      end
    end

    context "when the queue refresh is expecting a standard error" do
      let(:job) { NationalHearingQueueEntryRefreshJob.new }
      before do
        allow(NationalHearingQueueEntry).to receive(:refresh).and_raise(StandardError)
      end

      it "doesn't raise any errors" do
        expect do
          perform_enqueued_jobs { NationalHearingQueueEntryRefreshJob.perform_later }
        end.not_to raise_error
      end

      it "logs the error" do
        expect(job).to receive(:log_error)
        job.perform
      end
    end
  end
end
