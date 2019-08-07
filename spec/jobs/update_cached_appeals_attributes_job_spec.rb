# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

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

    it "records the jobs runtime with Datadog" do
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: UpdateCachedAppealsAttributesJob.name.underscore,
        metric_name: "runtime",
        metric_value: anything
      )

      UpdateCachedAppealsAttributesJob.perform_now
    end

    it "records the number of appeals cached with DataDog" do
      expect(DataDogService).to receive(:increment_counter).exactly(open_appeals.length).times

      UpdateCachedAppealsAttributesJob.perform_now
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

      expected_msg = "UpdateCachedAppealsAttributesJob failed after running for .*. Fatal error: #{error_msg}"

      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end
end
