# frozen_string_literal: true

describe Metrics::HearingsShowRate, :postgres do
  let(:start_date) { Time.zone.now - 31.days }
  let(:end_date) { Time.zone.now - 1.day }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }
  let(:disposition_counts) do
    {
      postponed: 5.0,
      held: 10.0,
      no_show: 3.0,
      cancelled: 2.0
    }
  end

  let(:total_hearings) { disposition_counts.values.reduce(0) { |acc, count| acc + count } }
  let(:metric) { Metrics::HearingsShowRate.new(date_range) }

  before do
    disposition_counts.each do |disposition, count|
      (1..count).each do
        hearing_day = create(:hearing_day, scheduled_for: Time.zone.now - rand(1..29).days)
        create(
          :hearing,
          disposition: disposition.to_s,
          hearing_day: hearing_day
        )
      end
    end
  end

  subject { metric.call }

  it do
    expect(subject).to eq(disposition_counts[:held] / (total_hearings - disposition_counts[:postponed]))
    expect(metric.name).to eq "Hearings Show Rate"
    expect(metric.id).to eq "1812216039"
  end
end
