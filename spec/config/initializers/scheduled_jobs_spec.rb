# frozen_string_literal: true

RSpec.describe "SCHEDULED_JOBS" do
  describe "for all jobs" do
    SCHEDULED_JOBS.each_value do |job_class|
      it "#{job_class.name} is not queued in default queue" do
        expect(job_class.queue_name).not_to eq("default")
      end
    end
  end
end
