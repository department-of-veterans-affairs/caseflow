# frozen_string_literal: true

describe ReportRequestIssuesStatsJob, :all_dbs do
  context "when the entire job fails" do
    let(:error_msg) { "Some dummy error" }

    before do
      allow_any_instance_of(ReportRequestIssuesStatsJob).to receive(:report_request_issues_stats).and_raise(error_msg)
    end

    it "sends a message to Slack that includes the error" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      ReportRequestIssuesStatsJob.perform_now

      expected_msg = "ReportRequestIssuesStatsJob failed after running for .*. Fatal error: #{error_msg}"
      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  context "when the job runs successfully" do
    before do
      # open_appeals.each do |appeal|
      #   create_list(:bva_dispatch_task, 3, appeal: appeal)
      #   create_list(:ama_judge_task, 8, appeal: appeal)
      # end
    end

    # it "creates the correct number of cached appeals" do
    #   expect(CachedAppeal.all.count).to eq(0)
    #
    #   ReportRequestIssuesStatsJob.perform_now
    #
    #   expect(CachedAppeal.all.count).to eq(open_appeals.length)
    # end

    context "Datadog" do
      let(:emitted_gauges) { [] }
      let(:job_gauges) do
        emitted_gauges.select { |gauge| gauge[:metric_group] == "report_request_issues_stats_job" }
      end
      let(:runtime_gauges) do
        job_gauges.select { |gauge| gauge[:metric_name] == "runtime" }
      end
      let(:request_issues_stats_gauges) do
        job_gauges.select { |gauge| gauge[:metric_name] == "request_issues_stats" }
      end

      it "records the jobs runtime" do
        allow(DataDogService).to receive(:emit_gauge) do |args|
          puts "push1 ",args
          emitted_gauges.push(args)
        end

        ReportRequestIssuesStatsJob.perform_now

        expect(runtime_gauges.first).to include(
          app_name: "caseflow_job",
          metric_group: ReportRequestIssuesStatsJob.name.underscore,
          metric_name: "runtime",
          metric_value: anything
        )
      end

      it "records the number of appeals cached" do
        allow(DataDogService).to receive(:emit_gauge) do |args|
          puts "push2 ",args
          emitted_gauges.push(args)
        end

        ReportRequestIssuesStatsJob.perform_now

        expect(request_issues_stats_gauges.first[:metric_value]).to eq(10)
      end
    end
  end

end
