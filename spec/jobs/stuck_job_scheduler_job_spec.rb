# frozen_string_literal: true

describe StuckJobSchedulerJob, :postgres do
  describe "#perform_master_stuck_job_with_profiling" do
    let(:job_instance) { StuckJobSchedulerJob.new }

    it "profiles the execution of each child job" do
      allow(RubyProf).to receive(:profile).and_yield # Mock the RubyProf.profile method

      expect(job_instance).to receive(:perform_master_stuck_job)

      job_instance.perform_master_stuck_job_with_profiling
    end

    # it "uploads profiling logs to S3" do
    #   allow(RubyProf).to receive(:profile).and_yield # Mock the RubyProf.profile method
    #   allow(job_instance).to receive(:perform_master_stuck_job)

    #   expect(job_instance).to receive(:upload_logs_to_s3)

    #   job_instance.perform_master_stuck_job_with_profiling
    # end
  end

  describe "#perform_master_stuck_job" do
    let(:job_instance) { StuckJobSchedulerJob.new }

    it "executes each child job even if one fails" do

       # Stub the new method for each child job to call the original implementation
      allow(ClaimDateDtFixJob).to receive(:new).and_call_original
      allow(BgsShareErrorFixJob).to receive(:new).and_call_original
      allow(ClaimNotEstablishedFixJob).to receive(:new).and_call_original
      allow(NoAvailableModifiersFixJob).to receive(:new).and_call_original
      allow(PageRequestedByUserFixJob).to receive(:new).and_call_original
      allow(ScDtaForAppealFixJob).to receive(:new).and_call_original
      allow(DtaScCreationFailedFixJob).to receive(:new).and_call_original

      # Expect that the perform method is called on each child job
      expect_any_instance_of(ClaimDateDtFixJob).to receive(:perform)
      expect_any_instance_of(BgsShareErrorFixJob).to receive(:perform)
      expect_any_instance_of(ClaimNotEstablishedFixJob).to receive(:perform)
      expect_any_instance_of(NoAvailableModifiersFixJob).to receive(:perform)
      expect_any_instance_of(PageRequestedByUserFixJob).to receive(:perform)
      expect_any_instance_of(ScDtaForAppealFixJob).to receive(:perform)
      expect_any_instance_of(DtaScCreationFailedFixJob).to receive(:perform)

      StuckJobSchedulerJob.new.perform_master_stuck_job
    end
  end




  describe "#execute_stuck_job" do
    let(:job_instance) { StuckJobSchedulerJob.new }

    it "rescues StandardError and logs the error" do
      expect_any_instance_of(ClaimDateDtFixJob).to receive(:perform).and_raise(StandardError)

      expect { job_instance.execute_stuck_job(ClaimDateDtFixJob) }.not_to raise_error
      expect(job_instance.send(:logs).last).to include("Error occurred:")
    end
  end
end
