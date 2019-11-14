# frozen_string_literal: true

require "support/database_cleaner"

describe RequestIssueReporter, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let!(:issues) do
    [
      create(:request_issue, :rating),
      create(:request_issue, :nonrating),
      create(:request_issue, :unidentified)
    ]
  end

  describe "#as_csv" do
    subject { described_class.new.as_csv }

    it "returns CSV" do
      csv = subject
      expect(csv).to match(/2019-03-18,0,0,0,0\n2019-03-25,1,1,1,33.33/)
    end
  end
end
