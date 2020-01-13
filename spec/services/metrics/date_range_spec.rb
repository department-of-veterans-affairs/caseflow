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
end
