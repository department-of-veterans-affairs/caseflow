# frozen_string_literal: true

class JobThatIsGood < ApplicationJob
  queue_with_priority :high_priority
  application_attr :fake

  def perform(target = nil)
    target&.do_something("hello")
  end
end

describe "ApplicationJob" do
  let(:freeze_time_first_run) { Time.zone.local(2024, 8, 30, 19, 0, 20) }
  let(:freeze_time_second_run) { Time.zone.local(2024, 8, 30, 20, 0, 20) }

  context ".application_attr" do
    it "sets application request store" do
      JobThatIsGood.perform_now
      expect(RequestStore[:application]).to eq("fake_job")
    end
  end

  context "JobExecutionTime" do
    def job_execution_record_checks
      expect(JobExecutionTime.count).to eq(1)
      execution_time_record = JobExecutionTime.first
      expect(execution_time_record.job_name).to eq("JobThatIsGood")
      expect(execution_time_record.last_executed_at).to eq(Time.now.utc)
    end

    it "adds record to JobExecutionTime if the IGNORE_JOB_EXECUTION_TIME constant is false" do
      Timecop.freeze(freeze_time_first_run) do
        expect(JobExecutionTime.count).to eq(0)
        JobThatIsGood.perform_now

        job_execution_record_checks
      end
    end

    it "update existing record in JobExecutionTime table when job is run multiple times" do
      JobExecutionTime.create(job_name: JobThatIsGood.name, last_executed_at: 2.days.ago)

      Timecop.freeze(freeze_time_first_run) do
        expect(JobExecutionTime.count).to eq(1)
        JobThatIsGood.perform_now

        job_execution_record_checks
      end

      Timecop.freeze(freeze_time_second_run) do
        JobThatIsGood.perform_now
        expect(JobExecutionTime.count).to eq(1)
        execution_time_record = JobExecutionTime.first
        expect(execution_time_record.job_name).to eq("JobThatIsGood")
        expect(execution_time_record.last_executed_at).to eq(Time.now.utc)
      end
    end
  end

  context ".queue_with_priority" do
    it "performs with valid priority" do
      target = double("target")
      allow(target).to receive(:do_something)

      JobThatIsGood.perform_now target

      expect(target).to have_received(:do_something).with("hello").once
    end

    it "fails with invalid priority" do
      expect do
        class JobWithInvalidPriority < JobThatIsGood
          queue_with_priority :high
        end
      end.to raise_error(ApplicationJob::InvalidJobPriority, "high is not a valid job priority!")
    end
  end
end
