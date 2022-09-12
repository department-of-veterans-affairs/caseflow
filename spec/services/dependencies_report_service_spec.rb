# frozen_string_literal: true

describe DependenciesReportService do
  DEPENDENCIES_REPORT_WITH_OUTAGES = %w[BGS VACOLS].freeze
  DEPENDENCIES_REPORT_WITHOUT_OUTAGES = [].freeze

  before(:each) do
    Rails.cache.clear
  end

  subject { DependenciesReportService.dependencies_report }

  context "when there is an outage for only one system" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :display)
    end

    it "returns one degraded systems" do
      is_expected.to eq %w[BGS]
    end
  end

  context "when there is an outage for multiple systems" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :display)
      Rails.cache.write(:degraded_service_banner_vacols, :display)
    end

    it "returns muliple systems" do
      is_expected.to eq DEPENDENCIES_REPORT_WITH_OUTAGES
    end
  end

  context "when there is no system outages" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :hide)
      Rails.cache.write(:degraded_service_banner_vbms, :hide)
      Rails.cache.write(:degraded_service_banner_vva, :hide)
      Rails.cache.write(:degraded_service_banner_vacols, :hide)
      Rails.cache.write(:degraded_service_banner_gov_delivery, :hide)
      Rails.cache.write(:degraded_service_banner_va_dot_gov, :hide)
    end

    it "returns an empty array" do
      is_expected.to eq DEPENDENCIES_REPORT_WITHOUT_OUTAGES
    end
  end

  context "when there is an invalid value written to cache" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :invalid_entry)
    end

    it "returns and empty array" do
      is_expected.to eq DEPENDENCIES_REPORT_WITHOUT_OUTAGES
    end
  end

  context "whenever there is an error raised when accessing the Rails cache" do
    before { allow(Rails.cache).to receive(:read_multi).and_raise(StandardError, error_status) }

    let(:error_status) { "Could not retrieve statuses" }

    it "logs the error and returns false" do
      expect(Rails.logger).to receive(:warn).with(
        "Exception thrown while checking dependency "\
        "status: #{error_status}"
      )

      is_expected.to eq false
    end
  end

  context "throws error" do
    it "when Rails.cache fails" do
      allow(Rails.cache).to receive(:read_multi).and_raise("boom")
      expect(DependenciesReportService.dependencies_report).to eq false
    end
  end

  context "throws error" do
    it "when Rails.cache fails" do
      allow(Rails.cache).to receive(:read_multi).and_raise("boom")
      expect(DependenciesReportService.dependencies_report).to eq false
    end
  end
end
