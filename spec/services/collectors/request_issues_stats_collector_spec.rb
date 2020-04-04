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
      expect(stats).to include(
        { metric: "request_issues.unidentified", value: 9 },
        { metric: "request_issues.unidentified.status", value: 2, "status" => "removed" },
        { metric: "request_issues.unidentified.status", value: 7, "status" => "nil" },
        { metric: "request_issues.unidentified.benefit", value: 4, "benefit" => "compensation" },
        { metric: "request_issues.unidentified.benefit", value: 5, "benefit" => "pension" },
        { metric: "request_issues.unidentified.decision_review", value: 3, "decision_review" => "higherlevelreview" },
        { metric: "request_issues.unidentified.decision_review", value: 6, "decision_review" => "supplementalclaim" }
      )

      vet_count_stat = stats.select { |stat| stat[:metric] == "request_issues.unidentified.vet_count" }.first
      expect(vet_count_stat[:value]).to be_between(1, 9)
    end
  end
end
