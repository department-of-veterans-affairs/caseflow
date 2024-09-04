# frozen_string_literal: true

describe CaseflowJob, :postgres do
  class SomeCaseflowJob < CaseflowJob
    queue_with_priority :low_priority

    def perform
      Rails.logger.info "Doing something useful"
    end
  end

  subject { SomeCaseflowJob.perform_now }

  context "when a CaseflowJob doesn't explicitly report to DataDog" do
    before do
      expect(MetricsService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: "some_caseflow_job",
        metric_name: "runtime",
        metric_value: anything
      ).once
    end

    it "automatically reports runtime to DataDog" do
      subject
    end
  end

  context "#serialize_job_for_enqueueing" do
    subject do
      CaseflowJob.serialize_job_for_enqueueing(SomeCaseflowJob.new)
    end

    it "serializes the job into a hash" do
      result = subject

      expect(result.dig(:message_body, "job_class")).to eq "SomeCaseflowJob"
      expect(result.dig(:message_body, "queue_name")).to eq "caseflow_test_low_priority"
      expect(
        result.dig(:message_attributes, "shoryuken_class", :string_value)
      ).to eq "ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper"
    end
  end

  context "#enqueue_batch_of_jobs" do
    let(:queue_name) { "fake_queue" }

    subject do
      CaseflowJob.enqueue_batch_of_jobs(
        jobs_to_enqueue: jobs,
        name_of_queue: queue_name
      )
    end

    context "when the number of jobs exceeds 10" do
      let(:jobs) { Array.new(11).map { SomeCaseflowJob.new } }

      it "raises a MaximumBatchSizeViolationError" do
        expect { subject }.to raise_error(Caseflow::Error::MaximumBatchSizeViolationError)
      end
    end

    context "when the number of jobs doesn't exceed 10" do
      let(:jobs) { Array.new(2).map { SomeCaseflowJob.new } }

      it "does not raise a MaximumBatchSizeViolationError" do
        expect { subject }.to_not raise_error(Caseflow::Error::MaximumBatchSizeViolationError)
      end
    end
  end
end
