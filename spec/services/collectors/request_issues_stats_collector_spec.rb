# frozen_string_literal: true

require "stats_collector_job"

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

      expected_stats = [
        { metric: "request_issues.unidentified", value: 9 },
        { metric: "request_issues.unidentified.status", value: 2, "status" => "removed" },
        { metric: "request_issues.unidentified.status", value: 7, "status" => "nil" },
        { metric: "request_issues.unidentified.benefit", value: 4, "benefit" => "compensation" },
        { metric: "request_issues.unidentified.benefit", value: 5, "benefit" => "pension" },
        { metric: "request_issues.unidentified.decision_review", value: 3, "decision_review" => "higherlevelreview" },
        { metric: "request_issues.unidentified.decision_review", value: 6, "decision_review" => "supplementalclaim" }
      ]
      expect(stats).to include(*expected_stats)

      vet_count_stat = stats.detect { |stat| stat[:metric] == "request_issues.unidentified.vet_count" }
      expect(vet_count_stat[:value]).to be_between(1, 9)
    end

    context "when run in the StatsCollectorJob" do
      before do
        stub_const("StatsCollectorJob::DAILY_COLLECTORS",  { "my_collector" => described_class }.freeze)
        stub_const("StatsCollectorJob::WEEKLY_COLLECTORS", {})
        stub_const("StatsCollectorJob::MONTHLY_COLLECTORS", {})
      end

      let(:emitted_gauges) { [] }
      let(:collector_gauges) do
        emitted_gauges.select { |gauge| gauge[:metric_group] == StatsCollectorJob.name.underscore }
          .group_by { |gauge| gauge[:metric_name] }
      end

      let(:issue_status_gauge) do
        collector_gauges["request_issues.unidentified.status"].group_by { |gauge| gauge[:attrs]["status"] }
      end

      it "records stats with tags" do
        allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

        slack_msg = []
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg << first_arg }

        StatsCollectorJob.new.perform_now

        expect(slack_msg).not_to include(/Fatal error/)

        expect(collector_gauges["request_issues.unidentified"].first[:metric_value]).to eq(9)
        expect(issue_status_gauge["removed"].first[:metric_value]).to eq(2)
        expect(issue_status_gauge["nil"].first[:metric_value]).to eq(7)
      end
    end
  end
end
