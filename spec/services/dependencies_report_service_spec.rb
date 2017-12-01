require "rails_helper"

describe DependenciesReportService do
  DEPENDENCIES_REPORT_WITH_OUTAGES = <<-'EOF'.freeze
{
  "BGS":{"name":"BGS","up_rate_5":100.0},
  "VACOLS":{"name":"VACOLS","up_rate_5":10.0},
  "VBMS":{"name":"VBMS","up_rate_5":49.0},
  "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference",
    "up_rate_5":100.0}
}
  EOF
  DEPENDENCIES_REPORT_WITHOUT_OUTAGES = <<-'EOF'.freeze
{
  "BGS":{"name":"BGS","up_rate_5":100.0},
  "VACOLS":{"name":"VACOLS","up_rate_5":100.0},
  "VBMS":{"name":"VBMS","up_rate_5":51.0},
  "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference",
    "up_rate_5":100.0}
}
  EOF
  context "when there is an outage" do
    before do
      Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITH_OUTAGES)
    end

    it "returns degraded services" do
      expect(DependenciesReportService.find_degraded_dependencies).to eq %w(VACOLS VBMS)
      expect(DependenciesReportService.outage_present?).to be_truthy
    end
  end

  context "when there is no outage" do
    before do
      Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITHOUT_OUTAGES)
    end

    it "returns no outage" do
      expect(DependenciesReportService.find_degraded_dependencies).to be_empty
      expect(DependenciesReportService.outage_present?).to be_falsey
    end
  end

  # needed to reach 90% test coverage
  context "when dependencies report is invalid" do
    before do
      Rails.cache.write(:dependencies_report,
                        'This isn\'t JSON')
    end

    it "returns no outage" do
      expect(DependenciesReportService.outage_present?).to be_falsey
    end
  end

  context "when the degraded service banner has been enabled manually" do
    before do
      Rails.cache.write(:degraded_service_banner, :always_show)
    end

    it "returns degraded service" do
      expect(DependenciesReportService.outage_present?).to be_truthy
    end
  end

  context "when the degraded service banner has been disabled manually" do
    before do
      Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITH_OUTAGES)
      Rails.cache.write(:degraded_service_banner, :never_show)
    end

    it "returns no outage" do
      expect(DependenciesReportService.outage_present?).to be_falsey
    end
  end

  context "when the degraded service banner has been set to auto" do
    before do
      Rails.cache.write(:degraded_service_banner, :auto)
    end

    context "when there is an outage" do
      before do
        Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITH_OUTAGES)
      end

      it "returns degraded services" do
        expect(DependenciesReportService.find_degraded_dependencies).to eq %w(VACOLS VBMS)
        expect(DependenciesReportService.outage_present?).to be_truthy
      end
    end

    context "when there is no outage" do
      before do
        Rails.cache.write(
          :dependencies_report, DEPENDENCIES_REPORT_WITHOUT_OUTAGES)
      end

      it "returns no outage" do
        expect(DependenciesReportService.find_degraded_dependencies).to be_empty
        expect(DependenciesReportService.outage_present?).to be_falsey
      end
    end
  end
end
