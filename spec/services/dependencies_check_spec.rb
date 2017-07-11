require "rails_helper"

describe DependenciesCheck do

  context "when there is an outage" do
    before do
      Rails.cache.write(:dependencies_report,
      '{
        "BGS":{"name":"BGS","up_rate_5":100.0},
        "VACOLS":{"name":"VACOLS","up_rate_5":10.0},
        "VBMS":{"name":"VBMS","up_rate_5":49.0},
        "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference","up_rate_5":100.0}
      }')
    end

    it "returns degraded services" do
      expect(DependenciesCheck.find_degraded_dependencies).to eq (["VACOLS", "VBMS"])
      expect(DependenciesCheck.outage_present?).to be_truthy
    end
  end

  context "when there is no outage" do
    before do
      Rails.cache.write(:dependencies_report,
      '{
        "BGS":{"name":"BGS","up_rate_5":100.0},
        "VACOLS":{"name":"VACOLS","up_rate_5":100.0},
        "VBMS":{"name":"VBMS","up_rate_5":51.0},
        "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference","up_rate_5":100.0}
      }')
    end

    it "returns no outage" do
      expect(DependenciesCheck.find_degraded_dependencies).to be_empty
      expect(DependenciesCheck.outage_present?).to be_falsey
    end
  end
end
