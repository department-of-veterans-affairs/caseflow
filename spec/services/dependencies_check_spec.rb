require "rails_helper"

describe DependenciesCheck do

  context "when there is an outage" do
    before do
      Rails.cache.write(:dependencies_report,
      "{\"BGS\":{\"name\":\"BGS\",\"env\":\"beplinktest\",\"time\":\"2017-07-10T14:13:18.160-04:00\",\"latency\":0.8413309229999868,\"service\":\"Person\",\"api\":\"findPersonByFileNumber\",\"pass\":true,\"count\":301,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":0.9690908690370892,\"latency60\":1.019690593135945},\"VACOLS\":{\"name\":\"VACOLS\",\"env\":\"vacols.dev.vaco.va.gov\",\"time\":\"2017-07-10T14:13:27.264-04:00\",\"latency\":0.10569705099987914,\"service\":\"VACOLS\",\"api\":\"VACOLS.BRIEFF\",\"pass\":true,\"count\":310,\"up_rate_5\":10.0,\"failed_rate_5\":0.0,\"latency10\":0.11946213020642259,\"latency60\":0.1252159982248306},\"VBMS\":{\"name\":\"VBMS\",\"env\":\"uat\",\"time\":\"2017-07-10T14:13:41.358-04:00\",\"latency\":1.3310489140003483,\"service\":\"VBMS\",\"api\":\"ListDocuments\",\"pass\":true,\"count\":298,\"up_rate_5\":49.0,\"failed_rate_5\":0.0,\"latency10\":1.6044549332031794,\"latency60\":1.4658587119853932},\"VBMS.FindDocumentSeriesReference\":{\"name\":\"VBMS.FindDocumentSeriesReference\",\"env\":\"uat\",\"time\":\"2017-07-10T14:13:17.079-04:00\",\"latency\":7.329530676999639,\"service\":\"VBMS\",\"api\":\"FindDocumentSeriesReference\",\"pass\":true,\"count\":242,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":8.1541093877157,\"latency60\":8.624709685363822}}")
    end

    it "returns degraded services" do
      expect(DependenciesCheck.find_degraded_dependencies).to eq (["VACOLS", "VBMS"])
      expect(DependenciesCheck.outage_present?).to be_truthy
    end
  end

  context "when there is no outage" do
    before do
      Rails.cache.write(:dependencies_report,
      "{\"BGS\":{\"name\":\"BGS\",\"env\":\"beplinktest\",\"time\":\"2017-07-10T14:13:18.160-04:00\",\"latency\":0.8413309229999868,\"service\":\"Person\",\"api\":\"findPersonByFileNumber\",\"pass\":true,\"count\":301,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":0.9690908690370892,\"latency60\":1.019690593135945},\"VACOLS\":{\"name\":\"VACOLS\",\"env\":\"vacols.dev.vaco.va.gov\",\"time\":\"2017-07-10T14:13:27.264-04:00\",\"latency\":0.10569705099987914,\"service\":\"VACOLS\",\"api\":\"VACOLS.BRIEFF\",\"pass\":true,\"count\":310,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":0.11946213020642259,\"latency60\":0.1252159982248306},\"VBMS\":{\"name\":\"VBMS\",\"env\":\"uat\",\"time\":\"2017-07-10T14:13:41.358-04:00\",\"latency\":1.3310489140003483,\"service\":\"VBMS\",\"api\":\"ListDocuments\",\"pass\":true,\"count\":298,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":1.6044549332031794,\"latency60\":1.4658587119853932},\"VBMS.FindDocumentSeriesReference\":{\"name\":\"VBMS.FindDocumentSeriesReference\",\"env\":\"uat\",\"time\":\"2017-07-10T14:13:17.079-04:00\",\"latency\":7.329530676999639,\"service\":\"VBMS\",\"api\":\"FindDocumentSeriesReference\",\"pass\":true,\"count\":242,\"up_rate_5\":100.0,\"failed_rate_5\":0.0,\"latency10\":8.1541093877157,\"latency60\":8.624709685363822}}")
    end

    it "returns no outage" do
      expect(DependenciesCheck.find_degraded_dependencies).to be_empty
      expect(DependenciesCheck.outage_present?).to be_falsey
    end
  end
end
