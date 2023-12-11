# frozen_string_literal: true

require_relative Rails.root.join("lib", "helpers", "master_scheduler_interface.rb")

shared_examples "a Master Scheduler serializable object" do |job_class|
  describe "when the job implements all of the required methods it" do
    # # Check if the method raises an error if not implemented
    it "implements perform method" do
      expect(subject.class.instance_methods(false).include?(:perform)).to be_truthy
    end

    it "implements records_with_errors method" do
      expect(subject.class.instance_methods(false).include?(:records_with_errors)).to be_truthy
    end

    it "implements error_text method" do
      expect(subject.class.instance_methods(false).include?(:error_text)).to be_truthy
    end

    it "implements process_records method" do
      expect(subject.class.instance_methods(false).include?(:process_records)).to be_truthy
    end

    it "implements loop_through_and_call_process_records method" do
      expect(subject.class.instance_methods(false).include?(:loop_through_and_call_process_records)).to be_truthy
    end

    it "implements log_processing_time method" do
      expect(subject.class.instance_methods(false).include?(:log_processing_time)).to be_truthy
    end

    it "implements capture_start_time method" do
      expect(subject.class.instance_methods(false).include?(:capture_start_time)).to be_truthy
    end

    it "implements capture_end_time method" do
      expect(subject.class.instance_methods(false).include?(:capture_end_time)).to be_truthy
    end

    it "is intialized with StuckJobReportService" do
      expect(subject.instance_variable_get(:@stuck_job_report_service)).to be_an_instance_of(StuckJobReportService)
    end
  end

  describe "#perform" do
    it "calls jobs methods in correct order: capture_start_time, loop_through_and_call_process_records,
    capture_end_time, log_processing_time" do
      job = job_class.new

      expect(job).to receive(:capture_start_time).ordered
      expect(job).to receive(:loop_through_and_call_process_records).ordered
      expect(job).to receive(:capture_end_time).ordered
      expect(job).to receive(:log_processing_time).ordered

      job.perform
    end
  end
end

describe MasterSchedulerInterface, :postgres do
end
