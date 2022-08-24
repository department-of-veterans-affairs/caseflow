# frozen_string_literal: true

describe DependenciesReportService do
  DEPENDENCIES_REPORT_WITH_OUTAGES = %w[BGS VACOLS].freeze
  DEPENDENCIES_REPORT_WITHOUT_OUTAGES = [].freeze

  before(:each) do
    Rails.cache.clear
  end

  context "when there is an outage for only one system" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :display)
    end

    it "returns one degraded systems" do
      expect(DependenciesReportService.dependencies_report).to eq %w[BGS]
    end
  end

  context "when there is an outage for multiple systems" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :display)
      Rails.cache.write(:degraded_service_banner_vacols, :display)
    end

    it "returns muliple systems" do
      expect(DependenciesReportService.dependencies_report).to eq DEPENDENCIES_REPORT_WITH_OUTAGES
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
      expect(DependenciesReportService.dependencies_report).to eq DEPENDENCIES_REPORT_WITHOUT_OUTAGES
    end
  end

  context "when there is an invalid value written to cache" do
    before do
      Rails.cache.write(:degraded_service_banner_bgs, :invalid_entry)
    end

    it "returns and empty array" do
      expect(DependenciesReportService.dependencies_report).to eq DEPENDENCIES_REPORT_WITHOUT_OUTAGES
    end
  end
end
