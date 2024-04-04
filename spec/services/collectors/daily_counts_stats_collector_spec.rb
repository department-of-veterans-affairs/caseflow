# frozen_string_literal: true

require "stats_collector_job"

describe Collectors::DailyCountsStatsCollector do
  def random_time_of_day
    rand(0..23).hours + rand(0..59).minutes + rand(0..59).seconds
  end
  context "#collect_stats" do
    before do
      yesterday = Time.now.utc.yesterday.change(hour: 0, min: 0, sec: 0)
      2.times do
        create(:appeal, created_at: yesterday + random_time_of_day)
      end

      create(:judge_case_review, location: :quality_review)
      2.times do
        create(:attorney_case_review, created_at: yesterday + random_time_of_day)
      end

      3.times do
        create(:hearing, created_at: yesterday + random_time_of_day)
      end

      2.times do |i|
        create(:request_issue, :unidentified,
               benefit_type: "pension",
               created_at: yesterday + random_time_of_day,
               contention_reference_id: i,
               decision_review: create(:higher_level_review))
      end

      create(:establish_claim, aasm_state: :unassigned, created_at: yesterday + random_time_of_day)
    end

    it "returns daily stats" do
      expect(subject.collect_stats).to match_array(
        [
          { :metric => "daily_counts.totals.claimant.decision_review", :value => 5, "decision_review" => "appeal" },
          { :metric => "daily_counts.totals.claimant.payee_code", :value => 5, "payee_code" => "00" },
          { :metric => "daily_counts.totals.hearing.disposition", :value => 3, "disposition" => "nil" },
          { :metric => "daily_counts.totals.case_review", :value => 1, "case_review" => "judge" },
          { :metric => "daily_counts.totals.case_review", :value => 2, "case_review" => "attorney" },
          { :metric => "daily_counts.totals.req_issue", :value => 2, "req_issue" => "higher_level_review" },
          { :metric => "daily_counts.totals.claim_establishment", :value => 1, "claim_establishment" => "nil" },
          { :metric => "daily_counts.totals.dispatch", :value => 1, "dispatch" => "establish_claim.unassigned" },
          { :metric => "daily_counts.increments.counts", :value => 2, "counts" => "appeal" },
          { :metric => "daily_counts.increments.counts", :value => 0, "counts" => "legacy_appeal" },
          { :metric => "daily_counts.increments.counts", :value => 0, "counts" => "appeal_series" },
          { :metric => "daily_counts.increments.counts", :value => 3, "counts" => "hearing" },
          { :metric => "daily_counts.increments.counts", :value => 0, "counts" => "legacy_hearing" },
          { :metric => "daily_counts.increments.appeal", :value => 2, "appeal" => "evidence_submission" },
          { :metric => "daily_counts.increments.appeal.status", :value => 2, "status" => "unknown" }
        ]
      )
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

      let(:case_review_gauge) do
        collector_gauges["daily_counts.totals.case_review"].group_by { |gauge| gauge[:attrs]["case_review"] }
      end

      it "records stats with tags" do
        allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

        slack_msg = []
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg << first_arg }

        StatsCollectorJob.new.perform_now

        expect(slack_msg).not_to include(/Fatal error/)

        expect(collector_gauges["daily_counts.increments.appeal"].first[:metric_value]).to eq(2)
        expect(case_review_gauge["judge"].first[:metric_value]).to eq(1)
        expect(case_review_gauge["attorney"].first[:metric_value]).to eq(2)
      end
    end
  end
end
