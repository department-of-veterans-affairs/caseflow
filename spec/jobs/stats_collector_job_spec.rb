# frozen_string_literal: true

describe StatsCollectorJob do
  context "when the entire job fails" do
    let(:error_msg) { "Some dummy error" }

    it "sends a message to Slack that includes the error" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      allow_any_instance_of(described_class).to receive(:run_collectors).and_raise(error_msg)
      described_class.perform_now

      expected_msg = "#{described_class.name} failed after running for .*. Fatal error: #{error_msg}"
      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  class ExampleDailyCollector
    def collect_stats
      [
        { "ex_metric_daily" => 9 },
        { "ex_metric_daily.stats1" => 2 },
        { "ex_metric_daily.statsA.metric2" => 4 }
      ]
    end
  end

  context "on different days" do
    class ExampleWeeklyCollector
      def collect_stats
        {}
      end
    end
    class ExampleMonthlyCollector
      def collect_stats
        {}
      end
    end

    before do
      stub_const("StatsCollectorJob::DAILY_COLLECTORS", "test_daily_collector" => ExampleDailyCollector)
      stub_const("StatsCollectorJob::WEEKLY_COLLECTORS", "test_weekly_collector" => ExampleWeeklyCollector)
      stub_const("StatsCollectorJob::MONTHLY_COLLECTORS", "test_monthly_collector" => ExampleMonthlyCollector)
    end
    context "on Tuesday (2020, 3, 24)" do
      it "daily collector runs" do
        expect_any_instance_of(ExampleDailyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleWeeklyCollector).not_to receive(:collect_stats)
        expect_any_instance_of(ExampleMonthlyCollector).not_to receive(:collect_stats)
        Timecop.freeze(2020, 3, 24) { described_class.perform_now }
      end
    end
    context "on Sunday (2020, 3, 22)" do
      it "daily and weekly collectors run" do
        expect_any_instance_of(ExampleDailyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleWeeklyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleMonthlyCollector).not_to receive(:collect_stats)
        Timecop.freeze(2020, 3, 22) { described_class.perform_now }
      end
    end
    context "on first day of the month (2020, 4, 1)" do
      it "daily and monthly collectors run" do
        expect_any_instance_of(ExampleDailyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleWeeklyCollector).not_to receive(:collect_stats)
        expect_any_instance_of(ExampleMonthlyCollector).to receive(:collect_stats)
        Timecop.freeze(2020, 4, 1) { described_class.perform_now }
      end
    end
    context "on first day of the month that is a Sunday (2020, 3, 1)" do
      it "daily, weekly, and monthly collectors run" do
        expect_any_instance_of(ExampleDailyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleWeeklyCollector).to receive(:collect_stats)
        expect_any_instance_of(ExampleMonthlyCollector).to receive(:collect_stats)
        Timecop.freeze(2020, 3, 1) { described_class.perform_now }
      end
    end
  end

  context "when the job runs successfully" do
    let(:daily_collectors) { { "test_daily_collector" => ExampleDailyCollector }.freeze }
    before do
      stub_const("StatsCollectorJob::DAILY_COLLECTORS", daily_collectors)
      stub_const("StatsCollectorJob::WEEKLY_COLLECTORS", {})
      stub_const("StatsCollectorJob::MONTHLY_COLLECTORS", {})
    end
    context "Datadog" do
      let(:emitted_gauges) { [] }
      let(:collector_gauges) do
        emitted_gauges.select { |gauge| gauge[:metric_group] == StatsCollectorJob.name.underscore }
          .group_by { |gauge| gauge[:metric_name] }
      end
      let(:runtime_gauges) do
        emitted_gauges.select { |gauge| gauge[:metric_name] == "runtime" }
          .index_by { |gauge| gauge[:metric_group] }
      end

      context "with a daily collector" do
        it "records the job's runtime and collector stats" do
          allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

          described_class.perform_now

          expect(runtime_gauges["stats_collector_job"][:metric_value]).not_to be_nil
          expect(runtime_gauges["stats_collector_job.test_daily_collector"][:metric_value]).not_to be_nil

          expect(collector_gauges["ex_metric_daily"].first[:metric_value]).to eq(9)
          expect(collector_gauges["ex_metric_daily.stats1"].first[:metric_value]).to eq(2)
          expect(collector_gauges["ex_metric_daily.statsA.metric2"].first[:metric_value]).to eq(4)
        end
      end

      context "with failing and daily collectors" do
        class FailingCollector
          def collect_stats
            fail "meant to fail"
          end
        end
        let(:daily_collectors) do
          {
            "failing_collector" => FailingCollector,
            "test_daily_collector" => ExampleDailyCollector
          }.freeze
        end

        it "records the job's runtime and collector stats despite a failing collector" do
          allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

          slack_msg = []
          allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg << first_arg }

          described_class.perform_now

          # check failing collector
          expect(runtime_gauges["stats_collector_job.failing_collector"][:metric_value]).not_to be_nil
          failure_msg = "failing_collector failed after running for less than a minute. Fatal error: meant to fail"
          expect(slack_msg.any? { |msg| msg.include?(failure_msg) }).to be_truthy
          # individual collector fails, but job completes
          success_msg = "StatsCollectorJob completed after running for less than a minute."
          expect(slack_msg.any? { |msg| msg.include?(success_msg) }).to be_truthy

          # check subsequent collector
          expect(runtime_gauges["stats_collector_job"][:metric_value]).not_to be_nil
          expect(runtime_gauges["stats_collector_job.test_daily_collector"][:metric_value]).not_to be_nil

          expect(collector_gauges["ex_metric_daily"].first[:metric_value]).to eq(9)
          expect(collector_gauges["ex_metric_daily.stats1"].first[:metric_value]).to eq(2)
          expect(collector_gauges["ex_metric_daily.statsA.metric2"].first[:metric_value]).to eq(4)
        end
      end

      context "with tagging collector" do
        class ExampleTaggingCollector
          def collect_stats
            [
              { "ex_tagged_metric" => 9 },
              { metric: "ex_tagged_metric.status", value: 3, "status": "open" },
              { metric: "ex_tagged_metric.status", value: 5, "status": "closed" }
            ]
          end
        end
        let(:daily_collectors) { { "tagging_collector" => ExampleTaggingCollector }.freeze }

        let(:status_gauge) do
          collector_gauges["ex_tagged_metric.status"].group_by { |gauge| gauge[:attrs][:status] }
        end

        it "records stats with tags when provided in collector results" do
          allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

          slack_msg = []
          allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg << first_arg }

          described_class.perform_now

          expect(slack_msg).not_to include(/Fatal error/)

          expect(collector_gauges["ex_tagged_metric"].first[:metric_value]).to eq(9)
          expect(status_gauge["open"].first[:metric_value]).to eq(3)
          expect(status_gauge["closed"].first[:metric_value]).to eq(5)
        end
      end
    end
  end
end
