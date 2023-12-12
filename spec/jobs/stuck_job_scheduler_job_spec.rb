# frozen_string_literal: true

require Rails.root.join("app", "jobs", "stuck_job_scheduler_job.rb")
# require Rails.root.join("lib", "helpers", "stuck_jobs_error_counter.rb")

describe StuckJobSchedulerJob, :postgres do
  # let(:stuck_job_report_service) { instance_double("StuckJobReportService") }
  let(:claim_date_dt_error) { "ClaimDateDt" }
  let(:page_error) { "Page requested by the user is unavailable" }
  let(:file_number) { "123456789" }
  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_date_dt_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
  end

  # This record will not be cleared
  let!(:bge_2) do
    create(:board_grant_effectuation,
           end_product_establishment_id: nil,
           decision_sync_error: page_error)
  end

  let!(:epe) do
    create(:end_product_establishment,
           established_at: Time.zone.now,
           veteran_file_number: file_number)
  end

  before do
    create_list(:decision_document, 9, error: claim_date_dt_error, processed_at: 7.days.ago,
                                       uploaded_to_vbms_at: 7.days.ago)
    create_list(:board_grant_effectuation, 15, end_product_establishment_id: epe.id, decision_sync_error: page_error)
  end

  subject { described_class.new }

  describe "#initialize" do
    it "initializes class with the correct attributes" do
      expect(subject.instance_variable_get(:@stuck_job_report_service)).to be_an_instance_of(StuckJobReportService)
      expect(subject.instance_variable_get(:@count)).to eq(0)
    end
  end

  describe "#perform" do
    it "sends logs to Slack after processing" do
      expect(subject).to receive(:slack_service).and_return(double(send_notification: nil))
      subject.perform
    end

    it "writes log report to AWS S3 after processing" do
      expect(subject.instance_variable_get(:@stuck_job_report_service)).to receive(:write_log_report).with(StuckJobSchedulerJob::REPORT_TEXT)
      subject.perform
    end

    it "captures end time after performing the job" do
      expect(subject).to receive(:end_time)
      subject.perform
    end
  end

  describe "#perform_parent_stuck_job" do
    it "executes execute_stuck_job for each job in STUCK_JOBS_ARRAY" do
      StuckJobSchedulerJob::STUCK_JOBS_ARRAY.each do |job_class|
        expect(subject).to receive(:execute_stuck_job).with(job_class)
      end
      subject.loop_through_stuck_jobs
    end
  end

  describe "#execute_stuck_job" do
    let(:stuck_job_class) { ClaimDateDtFixJob }

    it "increments the count based on initial and final error counts" do
      allow(stuck_job_class.new).to receive(:perform_now)
      expect { subject.execute_stuck_job(stuck_job_class) }.to(change { subject.instance_variable_get(:@count) })
    end
  end
end
