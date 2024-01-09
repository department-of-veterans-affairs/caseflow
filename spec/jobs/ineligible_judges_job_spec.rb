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

  describe "#case_distribution_ineligible_judges" do
    it "merges ineligible judges from different sources and store to cache" do
      # Stub the methods that fetch data from different sources
      allow(CaseDistributionIneligibleJudges).to receive(:caseflow_judges_with_vacols_records).and_return([{ css_id: "454" }])
      allow(CaseDistributionIneligibleJudges).to receive(:vacols_judges_with_caseflow_records).and_return([{ sdomainid: "123" }])

      result = job.send(:case_distribution_ineligible_judges)

      # Expect the result to be an array with merged data
      expect(result).to be_an(Array)
      expect(result).to include(css_id: "454") # Data from the first source
      expect(result).to include(sdomainid: "123") # Data from the second source
      expect(result.count).to eq 2
    end

    it "groups and merges data by css_id or sdomainid" do
      # Stub the methods that fetch data from different sources
      allow(CaseDistributionIneligibleJudges).to receive(:caseflow_judges_with_vacols_records).and_return([{ css_id: "123" }])
      allow(CaseDistributionIneligibleJudges).to receive(:vacols_judges_with_caseflow_records).and_return([{ sdomainid: "123" }])

      result = job.send(:case_distribution_ineligible_judges)

      # Expect the result to be an array with merged data grouped by '123'
      expect(result).to be_an(Array)
      expect(result).to include(css_id: "123", sdomainid: "123")
      expect(result.count).to eq 1
    end

    it "fetches ineligible judges from cache" do
      # Stub the methods that fetch data from different sources
      allow(CaseDistributionIneligibleJudges).to receive(:caseflow_judges_with_vacols_records).and_return([{ css_id: "123" }])
      allow(CaseDistributionIneligibleJudges).to receive(:vacols_judges_with_caseflow_records).and_return([{ sdomainid: "123" }])

      job.send(:case_distribution_ineligible_judges)
      result = Rails.cache.fetch("case_distribution_ineligible_judges")

      # Expect the result to be an array with merged data grouped by '123'
      expect(result).to be_an(Array)
      expect(result).to include(css_id: "123", sdomainid: "123")
      expect(result.count).to eq 1
    end
  end

  describe "#log_success" do
    let(:slack_service) { SlackService.new(url: "http://www.example.com") }
    it "logs success message with duration" do
      expect(Rails.logger).to receive(:info)
      allow(SlackService).to receive(:new).and_return(slack_service)
      allow(slack_service).to receive(:send_notification) { true }
      job.send(:log_success, Time.zone.now)
    end
  end
end
