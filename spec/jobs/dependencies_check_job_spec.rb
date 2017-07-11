require "rails_helper"

describe DependenciesCheckJob do

  context "it connect to Monitor" do
    it "writes report in cache" do
      # this should be changed to Monitor demo env URL, once it's ready
      # ENV["MONITOR_URL"] = "http://monitor.cf.uat.ds.va.gov/sample"
      # DependenciesCheckJob.perform_now
      # expect(Rails.cache.read(:dependencies_report)).to match(/up_rate_5/)
    end
  end
end
