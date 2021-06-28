# frozen_string_literal: true

describe ClaimReviewAsyncStatsReporter, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:veteran) { create(:veteran) }

  let!(:hlrs) do
    create(:higher_level_review, veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_last_submitted_at: 7.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_processed_at: 6.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 6.days.ago,
           establishment_canceled_at: 5.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_processed_at: 7.days.ago + 1.hour,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_processed_at: 7.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 27.days.ago,
           establishment_processed_at: 7.days.ago,
           veteran_file_number: veteran.file_number)
  end

  let!(:scs) do
    create(:supplemental_claim, veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 7.days.ago,
           establishment_last_submitted_at: 7.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 7.days.ago,
           establishment_processed_at: 6.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 6.days.ago,
           establishment_processed_at: 5.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 7.days.ago,
           establishment_canceled_at: 7.days.ago + 1.hour,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 7.days.ago,
           establishment_processed_at: 7.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 27.days.ago,
           establishment_processed_at: 7.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
  end

  let!(:rius) do
    create(:request_issues_update)
    create(:request_issues_update,
           submitted_at: 7.days.ago,
           processed_at: 5.days.ago)
    create(:request_issues_update,
           submitted_at: 6.days.ago,
           processed_at: 5.days.ago)
    create(:request_issues_update,
           submitted_at: 7.days.ago,
           processed_at: 7.days.ago + 1.hour)
    create(:request_issues_update,
           submitted_at: 7.days.ago,
           canceled_at: 7.days.ago + 4.hours)
  end

  describe "#stats" do
    subject { described_class.new.stats }

    it "returns nested hash" do
      expect(subject).to eq(
        supplemental_claims: {
          total: 6,
          expired: 1,
          in_progress: 1,
          canceled: 1,
          processed: 4,
          established_within_seven_days: 3,
          established_within_seven_days_percent: 50.0,
          median: 86_400.0,
          avg: 481_500.0,
          max: 1_738_800.0,
          min: 14_400.0
        },
        higher_level_reviews: {
          total: 6,
          expired: 1,
          in_progress: 1,
          canceled: 1,
          processed: 4,
          established_within_seven_days: 3,
          established_within_seven_days_percent: 50.0,
          median: 50_400.0,
          avg: 457_200.0,
          max: 1_724_400.0,
          min: 3_600.0
        },
        request_issues_updates: {
          total: 4,
          expired: 0,
          in_progress: 0,
          canceled: 1,
          processed: 3,
          established_within_seven_days: 3,
          established_within_seven_days_percent: 75.0,
          median: 86_400.0,
          avg: 87_600.0,
          max: 172_800.0,
          min: 3_600.0
        }
      )
    end
  end

  describe "#as_csv" do
    subject { described_class.new.as_csv }

    it "returns CSV" do
      csv = subject
      expect(csv).to match(/supplemental_claims,6,1,1,4,3,50.0,24:00:00,133:45:00,483:00:00,04:00:00/)
    end
  end
end
