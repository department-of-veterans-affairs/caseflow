# frozen_string_literal: true

describe Collectors::RequestIssuesStatsCollector do
  context "when unidentified RequestIssues with contentions exist" do
    before do
      start_of_last_month = Time.zone.now.last_month.beginning_of_month
      days_in_month = Time.days_in_month(start_of_last_month.month, start_of_last_month.year)
      3.times do |i|
        create(:request_issue, :unidentified,
               benefit_type: "pension",
               created_at: start_of_last_month + rand(0..days_in_month - 1).days,
               contention_reference_id: i,
               decision_review: create(:higher_level_review))
      end
      4.times do |i|
        create(:request_issue, :unidentified,
               benefit_type: "compensation",
               created_at: start_of_last_month + rand(0..days_in_month - 1).days,
               contention_reference_id: i + 100,
               decision_review: create(:supplemental_claim))
      end
      2.times do |i|
        create(:request_issue, :unidentified,
               benefit_type: "pension",
               closed_status: "removed",
               created_at: start_of_last_month + rand(0..days_in_month - 1).days,
               contention_reference_id: i + 200,
               decision_review: create(:supplemental_claim))
      end
    end

    it "records stats on unidentified request issues that have contentions" do
      stats = subject.collect_stats

      metric_name_prefix = described_class::METRIC_NAME_PREFIX
      expect(stats[metric_name_prefix]).to eq(9)
      expect(stats["#{metric_name_prefix}.vet_count"]).to be_between(1, 9)

      expect(stats["#{metric_name_prefix}.closed_status.removed"]).to eq(2)

      expect(stats["#{metric_name_prefix}.benefit.pension"]).to eq(5)
      expect(stats["#{metric_name_prefix}.benefit.compensation"]).to eq(4)

      expect(stats["#{metric_name_prefix}.decision_review.HigherLevelReview"]).to eq(3)
      expect(stats["#{metric_name_prefix}.decision_review.SupplementalClaim"]).to eq(6)
    end
  end
end
