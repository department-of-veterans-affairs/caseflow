# frozen_string_literal: true

describe UpdateCachedAppealsAttributesJob, :all_dbs do
  subject { UpdateCachedAppealsAttributesJob.perform_now }

  let(:vacols_case1) { create(:case, :travel_board_hearing) }
  let(:vacols_case2) { create(:case, :video_hearing_requested, :travel_board_hearing) }
  let(:vacols_case3) { create(:case, :travel_board_hearing) }

  let(:legacy_appeal1) { create(:legacy_appeal, vacols_case: vacols_case1) } # travel
  let(:legacy_appeal2) { create(:legacy_appeal, vacols_case: vacols_case2) } # video

  context "when the job runs successfully" do
    let(:legacy_appeals) { [legacy_appeal1, legacy_appeal2] }
    let(:appeals) { create_list(:appeal, 5) }
    let(:open_appeals) { appeals + legacy_appeals }
    let(:closed_legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case3) }

    before do
      open_appeals.each do |appeal|
        create_list(:bva_dispatch_task, 3, appeal: appeal)
        create_list(:ama_judge_assign_task, 8, appeal: appeal)
      end
    end

    it "creates the correct number of cached appeals" do
      expect(CachedAppeal.all.count).to eq(0)

      subject

      expect(CachedAppeal.all.count).to eq(open_appeals.length)
    end

    it "does not cache appeals when all appeal tasks are closed" do
      task_to_close = create(:ama_judge_assign_task,
                             appeal: closed_legacy_appeal,
                             status: Constants.TASK_STATUSES.assigned)
      task_to_close.update(status: Constants.TASK_STATUSES.completed)

      subject

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

        subject

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

        subject

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

      subject

      expected_msg = "UpdateCachedAppealsAttributesJob failed after running for .*. See Sentry event .*"

      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  context "caches hearing_request_type and former_travel correctly" do
    let(:appeal) { create(:appeal, closest_regional_office: "C") } # central
    let(:legacy_appeal3) do # former travel, currently virtual
      create(
        :legacy_appeal,
        vacols_case: vacols_case3,
        changed_request_type: HearingDay::REQUEST_TYPES[:virtual]
      )
    end

    let(:open_appeals) do
      [appeal, legacy_appeal1, legacy_appeal2, legacy_appeal3]
    end

    before do
      open_appeals.each do |appeal|
        create_list(:bva_dispatch_task, 3, appeal: appeal)
        create_list(:ama_judge_assign_task, 8, appeal: appeal)
      end
    end

    it "creates the correct number of cached appeals" do
      expect(CachedAppeal.all.count).to eq(0)

      subject

      expect(CachedAppeal.all.count).to eq(open_appeals.length)
    end

    it "caches hearing_request_type correctly", :aggregate_failures do
      subject

      expect(CachedAppeal.find_by(appeal_id: appeal.id).hearing_request_type).to eq("Central")
      expect(CachedAppeal.find_by(vacols_id: legacy_appeal1.vacols_id).hearing_request_type).to eq("Travel")
      expect(CachedAppeal.find_by(vacols_id: legacy_appeal2.vacols_id).hearing_request_type).to eq("Video")
      expect(CachedAppeal.find_by(vacols_id: legacy_appeal3.vacols_id).hearing_request_type).to eq("Virtual")
    end

    it "caches former_travel correctly", :aggregate_failures do
      subject

      # always nil for ama appeal
      expect(CachedAppeal.find_by(appeal_id: appeal.id).former_travel).to eq(nil)

      expect(CachedAppeal.find_by(vacols_id: legacy_appeal1.vacols_id).former_travel).to eq(false)
      expect(CachedAppeal.find_by(vacols_id: legacy_appeal2.vacols_id).former_travel).to eq(false)
      expect(CachedAppeal.find_by(vacols_id: legacy_appeal3.vacols_id).former_travel).to eq(true)
    end

    context "when BGS fails" do
      shared_examples "rescues error" do
        it "completes and sends warning to Slack" do
          slack_msg = ""
          allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

          job = described_class.new
          job.perform_now
          expect(job.warning_msgs.count).to eq 3

          expect(slack_msg.lines.count).to eq 4
          expected_msg = "\\[WARN\\] UpdateCachedAppealsAttributesJob .*"
          expect(slack_msg).to match(/#{expected_msg}/)
        end
      end

      context "BGSService fails with ECONNRESET" do
        before do
          bgs = Fakes::BGSService.new
          allow(Fakes::BGSService).to receive(:new).and_return(bgs)
          allow(bgs).to receive(:fetch_person_by_ssn)
            .and_raise(Errno::ECONNRESET, "mocked error for testing")
        end
        include_examples "rescues error"
      end
      context "BGSService fails with Savon::HTTPError" do
        before do
          bgs = Fakes::BGSService.new
          allow(Fakes::BGSService).to receive(:new).and_return(bgs)

          httperror_mock = double("httperror")
          allow(httperror_mock).to receive(:code).and_return(408)
          allow(httperror_mock).to receive(:headers).and_return({})
          allow(httperror_mock).to receive(:body).and_return("stream timeout")
          allow(bgs).to receive(:fetch_poa_by_file_number)
            .and_raise(Savon::HTTPError, httperror_mock)
        end
        include_examples "rescues error"
      end
    end
  end
end
