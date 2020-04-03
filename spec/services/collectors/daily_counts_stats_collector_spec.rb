# frozen_string_literal: true

describe Collectors::DailyCountsStatsCollector do
  def random_time_today
    rand(0..23).hours + rand(0..59).minutes + rand(0..59).seconds
  end
  context "#collect_stats" do
    before do
      yesterday = Time.now.utc.yesterday.change(hour: 0, min: 0, sec: 0)
      2.times do
        create(:appeal, created_at: yesterday + random_time_today)
      end

      create(:judge_case_review, location: :quality_review)
      2.times do
        create(:attorney_case_review, created_at: yesterday + random_time_today)
      end

      3.times do
        create(:hearing, created_at: yesterday + random_time_today)
      end

      2.times do |i|
        create(:request_issue, :unidentified,
               benefit_type: "pension",
               created_at: yesterday + random_time_today,
               contention_reference_id: i,
               decision_review: create(:higher_level_review))
      end
    end

    it "returns daily stats" do
      expect(subject.collect_stats).to include(
        "daily_counts.totals.claimant.decision_review.appeal" => 5,
        "daily_counts.totals.claimant.payee_code.00" => 5,
        "daily_counts.totals.hearing.nil" => 3,
        "daily_counts.totals.case_review.judge" => 1,
        "daily_counts.totals.case_review.attorney" => 2,
        "daily_counts.totals.req_issues.higherlevelreview" => 2,
        "daily_counts.increments.appeal.evidence_submission" => 2,
        "daily_counts.increments.hearing" => 3,
        "daily_counts.increments.appeal.status.unknown" => 2
      )
    end
  end
end
