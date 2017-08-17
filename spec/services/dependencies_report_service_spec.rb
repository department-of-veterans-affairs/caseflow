require "rails_helper"

describe DependenciesReportService do
  context "when there is an outage" do
    before do
      Rails.cache.write(:dependencies_report,
                        '{
                          "BGS":{"name":"BGS","up_rate_5":100.0},
                          "VACOLS":{"name":"VACOLS","up_rate_5":10.0},
                          "VBMS":{"name":"VBMS","up_rate_5":49.0},
                          "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference",
                            "up_rate_5":100.0}
                        }')
    end

    it "returns degraded services" do
      expect(DependenciesReportService.find_degraded_dependencies).to eq %w(VACOLS VBMS)
      expect(DependenciesReportService.outage_present?).to be_truthy
    end
  end

  context "when there is no outage" do
    before do
      Rails.cache.write(:dependencies_report,
                        '{
                          "BGS":{"name":"BGS","up_rate_5":100.0},
                          "VACOLS":{"name":"VACOLS","up_rate_5":100.0},
                          "VBMS":{"name":"VBMS","up_rate_5":51.0},
                          "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference",
                            "up_rate_5":100.0}
                        }')
    end

    it "returns no outage" do
      expect(DependenciesReportService.find_degraded_dependencies).to be_empty
      expect(DependenciesReportService.outage_present?).to be_falsey
    end
  end

  context "when an outage has been declared manually" do
    before do
      Rails.cache.write(:degraded_service, true)
    end

    it "returns degraded service" do
      expect(DependenciesReportService.outage_present?).to be_truthy
    end
  end

  context "when an outage has been resolved manually" do
    before do
      Rails.cache.write(:degraded_service, false)
    end

    it "returns no outage" do
      expect(DependenciesReportService.outage_present?).to be_falsey
    end
  end
end
