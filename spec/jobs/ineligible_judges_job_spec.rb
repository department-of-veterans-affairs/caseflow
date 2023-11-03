# frozen_string_literal: true

require "rails_helper" # Adjust this line based on your project's directory structure
require "timecop" # For time-related testing

RSpec.describe IneligibleJudgesJob, type: :job do
  let(:job) { described_class.new }
  let(:start_time) { Time.zone.now }

  before do
    # Freeze time to ensure consistent time measurements in the test
    Timecop.freeze(start_time)
  end

  after do
    Timecop.return
  end

  describe "perform method to test the execution" do
    it "calls #case_distribution_ineligible_judges and logs success" do
      expect(job).to receive(:case_distribution_ineligible_judges)
      expect(job).to receive(:log_success)

      job.perform
    end

    it "catches and logs errors" do
      allow(job).to receive(:case_distribution_ineligible_judges).and_raise(StandardError)
      expect(job).to receive(:log_error)

      job.perform
    end
  end
end
