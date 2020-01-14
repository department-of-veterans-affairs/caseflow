# frozen_string_literal: true

describe ExpiredAsyncJobsChecker, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:veteran) { create(:veteran) }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_last_submitted_at: 7.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "bad problem",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc) do
    create(:supplemental_claim,
           establishment_submitted_at: 6.days.ago,
           establishment_last_submitted_at: 6.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "problem\nwith multiple\nlines",
           veteran_file_number: veteran.file_number)
  end

  describe "#call" do
    it "finds 2 expired jobs" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/2 expired unfinished asyncable jobs exist in the queue/)
    end
  end
end
