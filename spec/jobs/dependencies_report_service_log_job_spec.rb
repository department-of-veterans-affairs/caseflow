# frozen_string_literal: true

describe DependenciesReportServiceLogJob do
  context "when outage is present" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :display)
    end

    it "should log the correct error message" do
      expect(Rails.logger).to receive(:error).with("Caseflow Monitor shows possible outages")
      DependenciesReportServiceLogJob.perform_now
    end
  end
end
