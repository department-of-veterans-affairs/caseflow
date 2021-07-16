# frozen_string_literal: true

describe CaseflowJob, :postgres do
  include_context "Metrics Reports"

  class SomeCaseflowJob < CaseflowJob
    queue_with_priority :low_priority

    def perform
      Rails.logger.info "Doing something useful"
    end
  end

  subject { SomeCaseflowJob.perform_now }

  context "when a CaseflowJob doesn't explicitly report to DataDog" do
    before do
      expect(DataDogService).to receive(:emit_gauge).with(
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
end
