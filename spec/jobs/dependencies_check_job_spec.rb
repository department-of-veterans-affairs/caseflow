require "rails_helper"

describe DependenciesCheckJob do
  context "when Monitor env is set" do
    before do
      allow_any_instance_of(HTTPI::Response).to receive(:raw_body).and_return('{
        "BGS":{"name":"BGS","up_rate_5":100.0},
        "VACOLS":{"name":"VACOLS","up_rate_5":10.0},
        "VBMS":{"name":"VBMS","up_rate_5":49.0},
        "VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference","up_rate_5":100.0}
      }')
    end
    it "writes report in cache" do
      stub_const("ENV", "MONITOR_URL" => "http://www.example.com")
      DependenciesCheckJob.perform_now
      expect(Rails.cache.read(:dependencies_report)).to match(/up_rate_5/)
    end

    it "when invalid url, it catches error" do
      stub_const("ENV", "MONITOR_URL" => "www.example.com")
      DependenciesCheckJob.perform_now
    end
  end

  context "when Monitor env is not set" do
    it "returns with no error" do
      stub_const("ENV", "MONITOR_URL" => nil)
      DependenciesCheckJob.perform_now
    end
  end
end
