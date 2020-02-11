# frozen_string_literal: true

describe Metrics::CertificationUsage, :all_dbs do
  let(:start_date) { Time.zone.now - 31.days }
  let(:end_date) { Time.zone.now - 1.day }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }

  describe "#call" do
    subject { described_class.new(date_range).call }

    let!(:paperless_cases) do
      10.times do
        vacols_case = create(:case, :certified, :type_original)
        vacols_case.folder.update!(tivbms: "Y")
      end
    end

    let!(:paper_cases) do
      5.times do
        vacols_case = create(:case, :certified, :type_original)
        vacols_case.folder.update!(tivbms: "N")
      end
    end

    let!(:paperless_not_caseflow_cases) do
      5.times do
        vacols_case = create(:case, :type_original, bf41stat: 3.days.ago)
        vacols_case.folder.update!(tivbms: "Y")
      end
    end

    let!(:paper_not_caseflow_cases) do
      5.times do
        vacols_case = create(:case, :type_original, bf41stat: 3.days.ago)
        vacols_case.folder.update!(tivbms: "N")
      end
    end

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
