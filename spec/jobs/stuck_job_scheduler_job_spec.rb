# frozen_string_literal: true

describe StuckJobSchedulerJob, :postgres do
  describe "#perform_master_stuck_job_with_profiling" do
    let(:job_instance) { StuckJobSchedulerJob.new }

    it "profiles the execution of each child job" do
      allow(RubyProf).to receive(:profile).and_yield # Mock the RubyProf.profile method

      expect(job_instance).to receive(:perform_master_stuck_job)

      job_instance.perform_master_stuck_job_with_profiling
    end
  end

  describe "#perform_master_stuck_job" do
    it "executes each child job even if one fails" do
      # Expect that the perform method is called on each child job
      expect_any_instance_of(ClaimDateDtFixJob).to receive(:perform)
      expect_any_instance_of(BgsShareErrorFixJob).to receive(:perform)
      expect_any_instance_of(ClaimNotEstablishedFixJob).to receive(:perform)
      expect_any_instance_of(NoAvailableModifiersFixJob).to receive(:perform)
      expect_any_instance_of(PageRequestedByUserFixJob).to receive(:perform)
      expect_any_instance_of(ScDtaForAppealFixJob).to receive(:perform)
      expect_any_instance_of(DtaScCreationFailedFixJob).to receive(:perform)
      # Add additional stuck jobs here

      StuckJobSchedulerJob.new.perform_master_stuck_job
    end
  end
end
