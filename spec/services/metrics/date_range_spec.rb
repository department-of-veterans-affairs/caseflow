# frozen_string_literal: true

describe Metrics::DateRange do
  let(:start_date) { Time.zone.now - 30.days }
  let(:end_date) { Time.zone.now - 1.day }

  subject { Metrics::DateRange.new(start_date, end_date).valid? }

  it { expect(subject).to be_truthy }

  context "invalid start date" do
    let(:start_date) { "" }

    it { expect(subject).to be_falsey }
  end

  context "invalid end date" do
    let(:end_date) { "" }

    it { expect(subject).to be_falsey }
  end

  describe ".for_fiscal_year" do
    context "FY 2020" do
      it "contains range for 2019-10" do
        ranges = described_class.for_fiscal_year('2020')
        expect(ranges).to include(Metrics::DateRange.new(Date.new(2019, 10, 1), Date.new(2019, 10, 31)))
      end
    end
  end
end
