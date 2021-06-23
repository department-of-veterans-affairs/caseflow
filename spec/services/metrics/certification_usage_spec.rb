# frozen_string_literal: true

describe Metrics::CertificationUsage, :all_dbs do
  include_context "Metrics Reports"

  describe "#call" do
    subject { described_class.new(date_range).call }

    it "reports total and paperless metrics" do
      expect(subject).to eq(
        certified_total: 25,
        certified_paperless: 15, # paperless_cases + paperless_not_caseflow_cases
        certified_with_caseflow: 15, # paperless_cases + paper_cases
        total_metric: 60.0,
        paperless_metric: 100.0
      )
    end
  end
end
