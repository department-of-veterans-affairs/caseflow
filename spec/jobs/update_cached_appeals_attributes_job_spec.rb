# frozen_string_literal: true

describe UpdateCachedAppealsAttributesJob, :all_dbs do
  let(:vacols_case1) { create(:case) }
  let(:vacols_case2) { create(:case) }
  let(:vacols_case3) { create(:case) }
  let!(:legacy_appeal1) { create(:legacy_appeal, vacols_case: vacols_case1) }
  let!(:legacy_appeal2) { create(:legacy_appeal, vacols_case: vacols_case2) }
  let(:legacy_appeals) { [legacy_appeal1, legacy_appeal2] }
  let(:appeals) { create_list(:appeal, 5) }
  let(:open_appeals) { appeals + legacy_appeals }
  let(:closed_legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case3) }

  context "when the job runs successfully" do
    before do
      open_appeals.each do |appeal|
        create_list(:bva_dispatch_task, 3, appeal: appeal)
        create_list(:ama_judge_task, 8, appeal: appeal)
      end
    end

    it "creates the correct number of cached appeals" do
      expect(CachedAppeal.all.count).to eq(0)

      UpdateCachedAppealsAttributesJob.perform_now

      expect(CachedAppeal.all.count).to eq(open_appeals.length)
    end

    it "does not cache appeals when all appeal tasks are closed" do
      task_to_close = create(:ama_judge_task,
                             appeal: closed_legacy_appeal,
                             status: Constants.TASK_STATUSES.assigned)
      task_to_close.update(status: Constants.TASK_STATUSES.completed)

      UpdateCachedAppealsAttributesJob.perform_now

      expect(CachedAppeal.all.count).to eq(open_appeals.length)
    end

    context "Datadog" do
      let(:emitted_gauges) { [] }
      let(:job_gauges) do
        emitted_gauges.select { |gauge| gauge[:metric_group] == "update_cached_appeals_attributes_job" }
      end
      let(:cached_appeals_count_gauges) do
        job_gauges.select { |gauge| gauge[:metric_name] == "appeals_to_cache" }
      end
      let(:cached_vacols_legacy_cases_gauges) do
        job_gauges.select { |gauge| gauge[:metric_name] == "vacols_cases_cached" }
      end

      it "records the jobs runtime" do
        allow(DataDogService).to receive(:emit_gauge) do |args|
          emitted_gauges.push(args)
        end

        UpdateCachedAppealsAttributesJob.perform_now

        expect(job_gauges.first).to include(
          app_name: "caseflow_job",
          metric_group: UpdateCachedAppealsAttributesJob.name.underscore,
          metric_name: "runtime",
          metric_value: anything
        )
      end

      it "records the number of appeals cached" do
        allow(DataDogService).to receive(:increment_counter) do |args|
          emitted_gauges.push(args)
        end

        UpdateCachedAppealsAttributesJob.perform_now

        expect(cached_appeals_count_gauges.count).to eq(open_appeals.length)
        expect(cached_vacols_legacy_cases_gauges.count).to eq(legacy_appeals.length)
      end
    end
  end

  context "when the entire job fails" do
    let(:error_msg) { "Some dummy error" }

    before do
      allow_any_instance_of(UpdateCachedAppealsAttributesJob).to receive(:cache_ama_appeals).and_raise(error_msg)
    end

    it "sends a message to Slack that includes the error" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      UpdateCachedAppealsAttributesJob.perform_now

      expected_msg = "UpdateCachedAppealsAttributesJob failed after running for .*. See Sentry for error"

      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end
end
