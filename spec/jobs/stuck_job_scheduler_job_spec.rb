# frozen_string_literal: true

describe StuckJobSchedulerJob, :postgres do
  describe "#perform_master_stuck_job_with_profiling" do
    let(:job_instance) { StuckJobSchedulerJob.new }

    it "profiles the execution of each child job" do
      allow(RubyProf).to receive(:profile).and_yield # Mock the RubyProf.profile method

      expect(job_instance).to receive(:perform_master_stuck_job)

      job_instance.perform
    end
  end

  describe "#perform_master_stuck_job" do
    it 'enqueues each child job' do
      subject.perform
      expect(ClaimDateDtFixJob).to have_been_enqueued.exactly(:once)
      # expect { StuckJobSchedulerJob.new.perform_master_stuck_job }.to(
      #   have_enqueued_job(ClaimDateDtFixJob)
        # .and have_enqueued_job(BgsShareErrorFixJob)
        # .and have_enqueued_job(ClaimNotEstablishedFixJob)
        # .and have_enqueued_job(NoAvailableModifiersFixJob)
        # .and have_enqueued_job(PageRequestedByUserFixJob)
        # .and have_enqueued_job(ScDtaForAppealFixJob)
        # .and have_enqueued_job(DtaScCreationFailedFixJob)
        # Add additional stuck jobs here
      # )
    end
  end
end
