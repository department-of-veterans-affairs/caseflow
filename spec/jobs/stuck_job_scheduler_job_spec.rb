# frozen_string_literal: true

describe StuckJobSchedulerJob, :postgres do
  # describe "#perform_master_stuck_job_with_profiling" do
  #   let(:job_instance) { StuckJobSchedulerJob.new }

  #   it "profiles the execution of each child job" do
  #     allow(RubyProf).to receive(:profile).and_yield # Mock the RubyProf.profile method

  #     expect(job_instance).to receive(:perform_master_stuck_job)

  #     job_instance.perform
  #   end
  # end

  subject { described_class.new }

  describe "#perform_master_stuck_job" do
    it 'enqueues each child job' do


      expect {
        ClaimDateDtFixJob.perform_now
      }.to have_enqueued_job(ClaimDateDtFixJob).with(no_args)
        # allow(ClaimDateDtFixJob).to receive(:perform_later).and_return('asdas')
        # expect(ClaimDateDtFixJob).to receive(:perform_later)
        # allow(BgsShareErrorFixJob).to receive(:perform_later)
        # allow(ClaimNotEstablishedFixJob).to receive(:perform_later)
        # allow(NoAvailableModifiersFixJob).to receive(:perform_later)
        # allow(PageRequestedByUserFixJob).to receive(:perform_later)
        # allow(ScDtaForAppealFixJob).to receive(:perform_later)
        # allow(DtaScCreationFailedFixJob).to receive(:perform_later)
        # subject.perform
# binding.pry
        # expect(ClaimDateDtFixJob).to have_been_enqueued
      # expect { StuckJobSchedulerJob.new.perform_master_stuck_job }.to(
      #   have_been_enqueued(ClaimDateDtFixJob)
        # .and have_enqueued_job(BgsShareErrorFixJob)
        # .and have_enqueued_job(ClaimNotEstablishedFixJob)
        # .and have_enqueued_job(NoAvailableModifiersFixJob)
        # .and have_enqueued_job(PageRequestedByUserFixJob)
        # # .and have_enqueued_job(ScDtaForAppealFixJob)
        # .and have_enqueued_job(DtaScCreationFailedFixJob)
        # Add additional stuck jobs here
      # )

    end
  end
end
