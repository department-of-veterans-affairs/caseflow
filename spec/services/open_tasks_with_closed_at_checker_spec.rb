# frozen_string_literal: true

describe OpenTasksWithClosedAtChecker, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let!(:task) do
    task = create(:task, :assigned, appeal: create(:appeal))
    task.update!(closed_at: Time.zone.now)
    task
  end

  describe "#call" do
    it "reports one Task in bad state" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/1 open Task\(s\) with a closed_at value/)
    end
  end
end
