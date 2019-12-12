# frozen_string_literal: true

describe Metrics::NonDenialDecisions, :postgres do
  let(:start_date) { Time.zone.now - 31.days }
  let(:end_date) { Time.zone.now - 1.day }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }
  before do

  end

  subject { Metrics::NonDenialDecisions.new(date_range).call }

  it do
    expect(subject).to eq()
  end
end
