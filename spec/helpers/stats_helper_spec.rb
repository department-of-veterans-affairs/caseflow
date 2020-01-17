# frozen_string_literal: true

RSpec.describe StatsHelper, type: :helper do
  describe "#format_time_duration_stat" do
    it "returns ?? when seconds is undefined" do
      expect(format_time_duration_stat(nil)).to eq "?? <span class=\"cf-stat-unit\">sec</span>"
    end

    it "returns time formatted in seconds when it is less than a minute" do
      expect(format_time_duration_stat(30)).to eq "30.00 <span class=\"cf-stat-unit\">sec</span>"
    end

    it "returns time formatted in minutes when it is less than an hour" do
      expect(format_time_duration_stat(125)).to eq "2.00 <span class=\"cf-stat-unit\">min</span>"
    end

    it "returns time formatted in hours when it is less than a day" do
      expect(format_time_duration_stat(4000)).to eq "11.00 <span class=\"cf-stat-unit\">hours</span>"
    end

    it "returns time formatted in days when it is over a day" do
      expect(format_time_duration_stat(30_000)).to eq "3.00 <span class=\"cf-stat-unit\">days</span>"
    end
  end
end
