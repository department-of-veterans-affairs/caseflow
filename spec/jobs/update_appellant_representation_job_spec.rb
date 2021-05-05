# frozen_string_literal: true

describe UpdateAppellantRepresentationJob, :all_dbs do
  context "when the job runs successfully" do
    let(:new_task_count) { 3 }
    let(:closed_task_count) { 1 }
    let(:correct_task_count) { 6 }
    let(:error_count) { 0 }
    let(:changed_tasks_count) { new_task_count + closed_task_count + error_count }

    let(:vso_for_appeal) { {} }
    let(:vso_for_legacy_appeal) { {} }

    before do
      correct_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = [vso]
      end

      new_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        vso_for_appeal[appeal.id] = [vso]
      end

      closed_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = []
      end

      allow_any_instance_of(Appeal).to receive(:representatives) { |a| vso_for_appeal[a.id] }
      allow_any_instance_of(LegacyAppeal).to receive(:representatives) { |a| vso_for_legacy_appeal[a.id] }
    end

    it "runs the job as expected" do
      expect_any_instance_of(UpdateAppellantRepresentationJob).to_not receive(:log_error).with(anything, anything)
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: "update_appellant_representation_job",
        metric_name: "runtime",
        metric_value: anything
      )

      UpdateAppellantRepresentationJob.perform_now
    end

    context "when there are legacy appeals with disposition task" do
      let(:legacy_appeal_count) { 10 }

      let!(:legacy_appeals) do
        (1..legacy_appeal_count).map do |_|
          legacy_appeal = create(:legacy_appeal, vacols_case: create(:case))
          create(
            :assign_hearing_disposition_task,
            appeal: legacy_appeal,
            assigned_to: HearingsManagement.singleton,
            parent: create(:hearing_task, appeal: legacy_appeal, assigned_to: HearingsManagement.singleton)
          )
          vso_for_legacy_appeal[legacy_appeal.id] = [create(:vso)]

          legacy_appeal
        end
      end

      it "updates every legacy appeal" do
        UpdateAppellantRepresentationJob.perform_now

        legacy_appeals.each do |appeal|
          expect(appeal.reload.record_synced_by_job.first.processed_at.nil?).to eq(false)
          expect(appeal.tasks.of_type(:TrackVeteranTask).first.assigned_to)
            .to eq(vso_for_legacy_appeal[appeal.id].first)
        end
      end
    end

    it "sends the correct number of messages to DataDog and not send a message to Slack" do
      expect(DataDogService).to receive(:increment_counter).exactly(changed_tasks_count).times
      expect_any_instance_of(SlackService).to_not receive(:send_notification)

      UpdateAppellantRepresentationJob.perform_now
    end
  end

  context "when individual appeals throw errors" do
    let(:new_task_count) { 3 }
    let(:closed_task_count) { 1 }
    let(:correct_task_count) { 6 }
    let(:error_count) { 2 }

    before do
      vso_for_appeal = {}

      correct_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = [vso]
      end

      new_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        vso_for_appeal[appeal.id] = [vso]
      end

      closed_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = []
      end

      error_indicator = "RAISE ERROR"
      error_count.times do |_|
        appeal, vso = create_appeal_and_vso
        create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = error_indicator
      end

      allow_any_instance_of(Appeal).to receive(:representatives) do |a|
        fail "No representatives for appeal ID #{a.id}" if error_indicator == vso_for_appeal[a.id]

        vso_for_appeal[a.id]
      end
    end

    it "the job still runs to completion but sends the errors to DataDog" do
      args = {}
      allow(DataDogService).to receive(:emit_gauge) do |function_args|
        args = function_args
      end

      expect_any_instance_of(UpdateAppellantRepresentationJob).to_not receive(:log_error).with(anything, anything)

      observed_error_count = 0
      allow_any_instance_of(UpdateAppellantRepresentationJob).to receive(:increment_task_count) do |_, task_effect|
        observed_error_count += 1 if task_effect == "error"
      end

      UpdateAppellantRepresentationJob.perform_now

      expect(observed_error_count).to eq(error_count)
      expect(args[:app_name]).to eq(CaseflowJob.name.underscore)
      expect(args[:metric_group]).to eq(UpdateAppellantRepresentationJob.name.underscore)
      expect(args[:metric_name]).to eq("runtime")
      expect(args[:metric_value]).to_not be_nil
    end
  end

  context "when the entire job fails" do
    let(:error_msg) { "Some dummy error" }

    before do
      allow_any_instance_of(UpdateAppellantRepresentationJob).to receive(:appeals_to_update).and_raise(error_msg)
    end

    it "sends a message to Slack that includes the error" do
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: UpdateAppellantRepresentationJob.name.underscore,
        metric_name: "runtime",
        metric_value: anything
      )

      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      UpdateAppellantRepresentationJob.perform_now

      expected_msg = "UpdateAppellantRepresentationJob failed after running for .*. Fatal error: #{error_msg}"
      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  context "#when there are ama and legacy appeals" do
    let!(:legacy_appeals) do
      (1..legacy_appeal_count).map do |_|
        legacy_appeal = create(:legacy_appeal, vacols_case: create(:case))
        create(
          :assign_hearing_disposition_task,
          appeal: legacy_appeal,
          assigned_to: HearingsManagement.singleton,
          parent: create(:hearing_task, appeal: legacy_appeal, assigned_to: HearingsManagement.singleton)
        )

        legacy_appeal
      end
    end

    let!(:appeals) do
      (1..appeal_count).map do |_|
        appeal = create(:appeal)
        create(
          :root_task,
          appeal: appeal,
          assigned_to: Bva.singleton
        )

        appeal
      end
    end

    context "#appeals_to_update" do
      let(:legacy_appeal_count) { 10 }
      let(:appeal_count) { 10 }

      it "returns both legacy and ama appeals" do
        all_appeals = UpdateAppellantRepresentationJob.new.appeals_to_update

        expect(all_appeals).to match_array(legacy_appeals + appeals)
      end
    end

    context "#retrieve_number_to_update" do
      let(:legacy_appeal_count) { 3 }
      let(:appeal_count) { 6 }

      it "returns the appropriate ratio of legacy to ama" do
        stub_const("UpdateAppellantRepresentationJob::TOTAL_NUMBER_OF_APPEALS_TO_UPDATE", 3)
        appeal_counts = UpdateAppellantRepresentationJob.new.retrieve_number_to_update

        expect(appeal_counts[:number_of_legacy_appeals_to_update]).to eq(1)
        expect(appeal_counts[:number_of_appeals_to_update]).to eq(2)
      end
    end
  end
end

def create_appeal_and_vso
  appeal = create(:appeal)
  create(:root_task, appeal: appeal)
  vso = create(:vso)

  [appeal, vso]
end
