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
        job_gauges.select { |gauge| gauge[:metric_name] == "runtime" }.first
      end
      let(:metric_name_prefix) { ReportRequestIssuesStatsJob::METRIC_NAME_PREFIX }
      let(:unidentified_with_contention_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == metric_name_prefix }.first
      end

      let!(:req_issues) do
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

      it "records the job's runtime" do
        allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

        ReportRequestIssuesStatsJob.perform_now

        expect(runtime_gauges).to include(
          app_name: "caseflow_job",
          metric_group: ReportRequestIssuesStatsJob.name.underscore,
          metric_name: "runtime",
          metric_value: anything
        )
      end

      let(:vet_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.vet_count" }.first
      end
      let(:removed_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.st.removed" }.first
      end
      let(:pension_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.ben.pension" }.first
      end
      let(:compensation_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.ben.compensation" }.first
      end
      let(:hlr_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.dr.HigherLevelReview" }.first
      end
      let(:sc_count_gauge) do
        job_gauges.select { |gauge| gauge[:metric_name] == "#{metric_name_prefix}.dr.SupplementalClaim" }.first
      end

      it "records stats on unidentified request issues that have contentions" do
        allow(DataDogService).to receive(:emit_gauge) { |args| emitted_gauges.push(args) }

        ReportRequestIssuesStatsJob.perform_now

        expect(unidentified_with_contention_gauge[:metric_value]).to eq(9)
        expect(vet_count_gauge[:metric_value]).to be_between(1, 9)

        expect(removed_count_gauge[:metric_value]).to eq(2)

        expect(pension_count_gauge[:metric_value]).to eq(5)
        expect(compensation_count_gauge[:metric_value]).to eq(4)

        expect(hlr_count_gauge[:metric_value]).to eq(3)
        expect(sc_count_gauge[:metric_value]).to eq(6)
      end
    end
  end
end
