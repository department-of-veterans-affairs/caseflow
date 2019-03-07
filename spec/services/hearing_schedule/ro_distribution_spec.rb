# frozen_string_literal: true

describe HearingSchedule::RoDistribution do
  let(:ro_distribution) do
    Class.new { include HearingSchedule::RoDistribution }
  end

  context ".montly_percentage_for_period" do
    let(:start_date) { Date.parse("2018-04-15") }
    let(:end_date) { Date.parse("2018-08-31") }

    subject { ro_distribution.montly_percentage_for_period(start_date, end_date) }

    context "second half of 2018 fiscal year" do
      it do
        expect(subject).to eq([4, 2018] => 51.724137931034484, [5, 2018] => 100.0, [6, 2018] => 100.0,
                              [7, 2018] => 100.0, [8, 2018] => 100.0)
      end
    end

    context "first half of 2019 fiscal year" do
      let(:start_date) { Date.parse("2018-09-01") }
      let(:end_date) { Date.parse("2019-03-31") }

      it do
        expect(subject).to eq([9, 2018] => 100.0, [10, 2018] => 100.0, [11, 2018] => 100.0,
                              [12, 2018] => 100.0, [1, 2019] => 100.0, [2, 2019] => 100.0, [3, 2019] => 100.0)
      end
    end

    context "includes end of month" do
      let(:start_date) { Date.parse("2018-08-31") }
      let(:end_date) { Date.parse("2018-09-30") }

      it { expect(subject).to eq([8, 2018] => 0.0, [9, 2018] => 100.0) }
    end
  end

  context ".weight_by_percentages" do
    let(:monthly_percentages) { { [4, 2018] => 100.0, [5, 2018] => 100.0 } }
    subject { ro_distribution.weight_by_percentages(monthly_percentages) }

    context "get weight for months" do
      it { expect(subject).to eq([4, 2018] => 0.5, [5, 2018] => 0.5) }
    end

    context "six month full percentage" do
      let(:monthly_percentages) do
        { [4, 2018] => 100.0, [5, 2018] => 100.0, [6, 2018] => 100.0,
          [7, 2018] => 100.0, [8, 2018] => 100.0 }
      end
      it do
        expect(subject).to eq([4, 2018] => 0.2, [5, 2018] => 0.2, [6, 2018] => 0.2,
                              [7, 2018] => 0.2, [8, 2018] => 0.2)
      end
    end

    context "six month 100 percentage" do
      let(:monthly_percentages) { { [4, 2018] => 51.0, [5, 2018] => 100.0 } }
      it { expect(subject).to eq([4, 2018] => 0.33774834437086093, [5, 2018] => 0.6622516556291391) }
    end
  end

  context ".shuffle_grouped_monthly_dates" do
    let(:grouped_monthly_dates) do
      { [4, 2018] => [Date.parse("2018-04-01"),
                      Date.parse("2018-04-02"),
                      Date.parse("2018-04-03")] }
    end

    subject { ro_distribution.shuffle_grouped_monthly_dates(grouped_monthly_dates) }

    context "days are shuffled in the month" do
      it { expect(subject[[4, 2018]].keys.count).to eq(3) }
    end
  end
end
