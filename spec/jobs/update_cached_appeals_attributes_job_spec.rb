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

    context "when AOD appeals exist" do
      # nonpriority
      let(:appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:denied_aod_motion_appeal) do
        create(:appeal,
               :denied_advance_on_docket,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:inapplicable_aod_motion_appeal) do
        create(:appeal,
               :inapplicable_aod_motion,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let!(:hearing_appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.hearing)
      end
      let!(:evidence_submission_appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.evidence_submission)
      end
      let(:nonpriority_appeals) do
        [
          appeal, denied_aod_motion_appeal, inapplicable_aod_motion_appeal,
          hearing_appeal, evidence_submission_appeal
        ]
      end

      # priority
      let(:aod_age_appeal) do
        create(:appeal,
               :advanced_on_docket_due_to_age,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:age_aod_motion_appeal) do
        create(:appeal,
               :advanced_on_docket_due_to_age_motion,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:aod_motion_appeal) do
        create(:appeal,
               :advanced_on_docket_due_to_motion,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:aod_motion_directly_on_appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review).tap do |a|
          create(:advance_on_docket_motion, reason: :other, granted: true, appeal: a)
        end
      end
      let(:aod_based_on_age_field_appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review).tap { |a| a.update(aod_based_on_age: true) }
      end
      let(:priority_appeals) do
        [
          aod_age_appeal, age_aod_motion_appeal, aod_motion_appeal,
          aod_motion_directly_on_appeal, aod_based_on_age_field_appeal
        ]
      end

      let(:open_appeals) { appeals + legacy_appeals + nonpriority_appeals + priority_appeals }

      it "caches AOD status correctly" do
        expect(CachedAppeal.all.count).to eq(0)

        nonpriority_appeals.each do |nonpriority_appeal|
          expect(nonpriority_appeal.aod?).to be_falsey
        end
        priority_appeals.each do |priority_appeal|
          # do not call `aod_based_on_age_field_appeal.aod?` since that will
          # set `aod_based_on_age` to false due to claimant's age
          expect(priority_appeal.aod?) unless priority_appeal == aod_based_on_age_field_appeal
        end

        subject
        priority_appeal_ids = priority_appeals.map(&:id)
        CachedAppeal.all.each do |appeal|
          expect(appeal.is_aod).to be(priority_appeal_ids.include?(appeal.appeal_id))
        end
        expect(CachedAppeal.all.count).to eq(open_appeals.length)
      end
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

  context "caches hearing_request_type and formally_travel correctly" do
    let(:appeal) { create(:appeal, closest_regional_office: "C") } # central
    let(:legacy_appeal3) do # formally travel, currently virtual
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
      expect(CachedAppeal.find_by(appeal_id: legacy_appeal1.id).hearing_request_type).to eq("Travel")
      expect(CachedAppeal.find_by(appeal_id: legacy_appeal2.id).hearing_request_type).to eq("Video")
      expect(CachedAppeal.find_by(appeal_id: legacy_appeal3.id).hearing_request_type).to eq("Virtual")
    end

    it "caches formally_travel correctly", :aggregate_failures do
      subject

      # always nil for ama appeal
      expect(CachedAppeal.find_by(appeal_id: appeal.id).formally_travel).to eq(nil)

      expect(CachedAppeal.find_by(appeal_id: legacy_appeal1.id).formally_travel).to eq(false)
      expect(CachedAppeal.find_by(appeal_id: legacy_appeal2.id).formally_travel).to eq(false)
      expect(CachedAppeal.find_by(appeal_id: legacy_appeal3.id).formally_travel).to eq(true)
    end
  end
end
