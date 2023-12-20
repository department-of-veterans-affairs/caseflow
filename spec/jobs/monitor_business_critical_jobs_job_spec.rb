# frozen_string_literal: true

describe MonitorBusinessCriticalJobsJob do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2, 20))
    Time.zone = "UTC"

    # Loop through and set successful values for all jobs
    MonitorBusinessCriticalJobsJob::BUSINESS_CRITICAL_JOBS.each do |job_class|
      Rails.cache.write("#{job_class}_last_started_at", success_started_at)
      Rails.cache.write("#{job_class}_last_completed_at", success_completed_at)
    end
  end

  after do
    MonitorBusinessCriticalJobsJob::BUSINESS_CRITICAL_JOBS.each do |job_class|
      Rails.cache.write("#{job_class}_last_started_at", nil)
      Rails.cache.write("#{job_class}_last_completed_at", nil)
    end
  end

  let(:job) { MonitorBusinessCriticalJobsJob.new }
  let!(:success_started_at) { 1.hour.ago }
  let!(:success_completed_at) { 30.minutes.ago }

  context "#results" do
    subject { job.results }

    it "returns a hash" do
      expect(subject).to be_a(Hash)
      expect(subject.keys).to eq(MonitorBusinessCriticalJobsJob::BUSINESS_CRITICAL_JOBS)
      expect(subject["CreateEstablishClaimTasksJob"][:started]).to eq(success_started_at)
      expect(subject["CreateEstablishClaimTasksJob"][:completed]).to eq(success_completed_at)
    end
  end

  context "#perform" do
    context "when one job has failed to start or complete" do
      before do
        # Set up failure job to have jobs not run for 24 hours
        @failure_job_class = MonitorBusinessCriticalJobsJob::BUSINESS_CRITICAL_JOBS.last
        Rails.cache.write("#{@failure_job_class}_last_started_at", 1.day.ago)
        Rails.cache.write("#{@failure_job_class}_last_completed_at", 1.day.ago)
      end

      it "sends a slack notification with failure information" do
        included_values = [
          "Business critical job",
          "CreateEstablishClaimTasksJob: Last started: 2017-02-02",
          "PrepareEstablishClaimTasksJob: Last started: 2017-02-01",
          "#{@failure_job_class} failed to start in the last 5 hours",
          "#{@failure_job_class} failed to complete in the last 5 hours",
          "here"
        ]
        expect(job.slack_service).to receive(:send_notification)
          .with(including(*included_values))
        job.perform
      end
    end

    context "when all jobs have started/completed as expected" do
      it "does not @here channel if no failures" do
        excluded_values = [
          "failed to start",
          "failed to compelete",
          "here"
        ]
        expect(job.slack_service).to receive(:send_notification)
          .with(excluding(*excluded_values))
        job.perform
      end
    end
  end
end
