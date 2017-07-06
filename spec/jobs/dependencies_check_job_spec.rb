require "rails_helper"

describe DependenciesCheckJob do

  context "when there is an outage" do
    before do
      @report = {
        "BGS"=>
          {"name"=>"BGS",
           "up_rate_5"=>100.0},
        "VACOLS"=>
          {"name"=>"VACOLS",
             "up_rate_5"=>100.0},
        "VBMS"=>
          {"name"=>"VBMS",
           "up_rate_5"=>49.0},
        "VBMS.FindDocumentSeriesReference"=>
          {"name"=>"VBMS.FindDocumentSeriesReference",
            "up_rate_5"=>100.0}
      }

      allow_any_instance_of(DependenciesCheckJob).to receive(:poll_monitor).and_return(@report)
    end

    it "stores service name in cache" do
      DependenciesCheckJob.perform_now
      expect(Rails.cache.read(:dependencies_outage)).to eq("VBMS")
    end
  end

  context "when there is no outage" do
    before do
      @report = {
        "BGS"=>
          {"name"=>"BGS",
           "up_rate_5"=>100.0},
        "VACOLS"=>
          {"name"=>"VACOLS",
             "up_rate_5"=>100.0},
        "VBMS"=>
          {"name"=>"VBMS",
           "up_rate_5"=>51.0},
        "VBMS.FindDocumentSeriesReference"=>
          {"name"=>"VBMS.FindDocumentSeriesReference",
            "up_rate_5"=>100.0}
      }

      allow_any_instance_of(DependenciesCheckJob).to receive(:poll_monitor).and_return(@report)
    end

    it "stores nil in cache" do
      DependenciesCheckJob.perform_now
      expect(Rails.cache.read(:dependencies_outage)).to eq(nil)
    end
  end
end
