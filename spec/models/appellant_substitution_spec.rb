# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe AppellantSubstitution do
  describe ".create!" do
    subject { described_class.create!(params) }

    let(:created_by) { create(:user) }
    let(:source_appeal) { create(:appeal) }
    let(:substitution_date) { 5.days.ago.to_date }
    let(:substitute) { create(:claimant) }

    let(:substitutes_poa) { BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(substitute&.participant_id) }
    let(:poa_participant_id) { substitutes_poa.poa_participant_id }
    before do
      # Needed to enable InformalHearingPresentationTask to be created for target_appeal.representatives
      allow_any_instance_of(Representative).to receive(:should_write_ihp?) { true }
    end

    let(:selected_task_types) { [] }
    let(:selected_task_ids) { source_appeal.tasks.assigned_to_any_org.of_type(selected_task_types).pluck(:id) }
    let(:task_params) { {} }

    let(:params) do
      {
        created_by: created_by,
        source_appeal: source_appeal,
        substitution_date: substitution_date,
        claimant_type: substitute&.type,
        substitute_participant_id: substitute&.participant_id,
        poa_participant_id: poa_participant_id,
        selected_task_ids: selected_task_ids,
        task_params: task_params
      }
    end

    it "creates the record and new appeal is ready for distribution" do
      expect { subject }.not_to raise_error
      params.each_key { |key| expect(subject.send(key)).to eq params[key] }

      expect(subject.target_appeal.appellant_substitution).to eq subject
      expect(subject.target_appeal.appellant_substitution?).to eq true
      expect(subject.target_appeal.stream_type).to eq subject.source_appeal.stream_type
      expect(subject.target_appeal.docket_number).to eq subject.source_appeal.docket_number
      expect(subject.substitute_claimant.participant_id).to eq subject.substitute_participant_id
      expect(subject.target_appeal.claimant.participant_id).to eq subject.substitute_participant_id
      expect(subject.substitute_person).to eq subject.target_appeal.claimant.person
      expect(subject.substitute_person).not_to eq subject.source_appeal.claimant.person

      expect(subject.target_appeal.veteran_is_not_claimant).to eq true
      # No other task types are created
      expect(subject.target_appeal.tasks.map(&:type)).to match_array %w[RootTask DistributionTask]
    end

    context "when source appeal has ScheduleHearingTask and EvidenceSubmissionWindowTask" do
      let(:selected_task_types) do
        [:ScheduleHearingTask, :EvidenceSubmissionWindowTask, :InformalHearingPresentationTask]
      end
      let(:source_esw_task) do
        source_appeal.tasks.assigned_to_any_org.find_by(type: :EvidenceSubmissionWindowTask)
      end
      let(:task_params) do
        user_task_params = {}

        if source_esw_task
          user_task_params[source_esw_task.id] = { hold_end_date: evidence_submission_hold_end_date&.strftime("%F") }
        end

        user_task_params
      end
      let(:evidence_submission_hold_end_date) { Time.zone.today + rand(1..200).days }

      shared_examples "new appeal has user-selected ScheduleHearingTask task" do
        it "copies ScheduleHearingTask to nw appeal" do
          expect(source_appeal.tasks.of_type(:ScheduleHearingTask).count).to be > 0

          target_appeal = subject.target_appeal

          sched_hearing_task = target_appeal.tasks.open.find_by(type: :ScheduleHearingTask)
          expect(sched_hearing_task.status).to eq "assigned"
        end
      end

      shared_examples "new appeal has user-selected EvidenceSubmissionWindowTask task" do
        it "copies EvidenceSubmissionWindowTask to new appeal" do
          expect(source_appeal.tasks.of_type(:EvidenceSubmissionWindowTask).count).to be > 0

          target_appeal = subject.target_appeal

          esw_task = target_appeal.tasks.open.find_by(type: :EvidenceSubmissionWindowTask)
          expect(esw_task.status).to eq "assigned"

          # check hold end date for EvidenceSubmissionWindowTask is what was specified in task_params
          task_timer = TaskTimer.where(task: esw_task).order(:id).last
          expect(task_timer.submitted_at.utc.to_date).to eq evidence_submission_hold_end_date
          expect(esw_task.timer_ends_at.utc.to_date).to eq evidence_submission_hold_end_date
        end

        context "when ESWTask's task_param hold_end_date is not provided" do
          let(:evidence_submission_hold_end_date) { nil }
          it "fails" do
            expect { subject }.to raise_error(/Expecting hold_end_date creation parameter.*/)
          end
        end
      end

      shared_examples "new appeal has user-selected TrackVeteranTask and IHPTask tasks" do
        it "creates TrackVeteranTask and IHPTask assigned to POA" do
          expect(source_appeal.tasks.of_type(:InformalHearingPresentationTask).count).to be > 0
          source_ihp_task = source_appeal.tasks.assigned_to_any_org.find_by(type: :InformalHearingPresentationTask)
          expect(source_ihp_task.assigned_to.participant_id).not_to eq poa_participant_id

          target_appeal = subject.target_appeal

          track_vet_task = target_appeal.tasks.open.find_by(type: :TrackVeteranTask)
          expect(track_vet_task.status).to eq "in_progress"
          expect(track_vet_task.assigned_to.participant_id).to eq poa_participant_id

          ihp_task = target_appeal.tasks.open.find_by(type: :InformalHearingPresentationTask)
          expect(ihp_task.status).to eq "assigned"
          expect(ihp_task.assigned_to.participant_id).to eq poa_participant_id
        end
      end

      shared_examples "new appeal does not have post-distribution tasks" do
        let(:expected_task_types) do
          %w[RootTask DistributionTask TrackVeteranTask InformalHearingPresentationTask
             EvidenceSubmissionWindowTask ScheduleHearingTask]
        end
        it "doesn't create tasks typically created after DistributionTask is completed" do
          target_appeal = subject.target_appeal
          expect(target_appeal.tasks.map(&:type).uniq - expected_task_types).to be_empty
        end
      end

      let!(:source_appeal) do
        create(:appeal, :hearing_docket, :with_schedule_hearing_tasks, :dispatched) do |appeal|
          distribution_task = appeal.tasks.find_by(type: :DistributionTask)

          EvidenceSubmissionWindowTask.create!(appeal: appeal, parent: distribution_task)

          vso_participant_id = "55555"
          org = create(:vso, participant_id: vso_participant_id)
          org_task = create(:informal_hearing_presentation_task, assigned_to: org, parent: distribution_task)
          create(:informal_hearing_presentation_task, parent: org_task)

          # Cancel any open tasks
          appeal.tasks.open.map(&:cancelled!)
        end
      end

      include_examples "new appeal has user-selected ScheduleHearingTask task"
      include_examples "new appeal has user-selected EvidenceSubmissionWindowTask task"
      include_examples "new appeal does not have post-distribution tasks"

      it "doesn't create TrackVeteranTask or IHPTask" do
        # Since a Representative with poa_participant_id doesn't exist, a warning is sent
        expect_any_instance_of(InitialTasksFactory).to receive(:warn_poa_not_a_representative).and_call_original

        target_appeal = subject.target_appeal
        # Since a Representative with poa_participant_id doesn't exist, these tasks are not created
        expect(target_appeal.tasks.open.of_type(:TrackVeteranTask).count).to eq 0
        expect(target_appeal.tasks.open.of_type(:InformalHearingPresentationTask).count).to eq 0
      end

      context "when substitute's POA is a Representative (i.e., VSO or PrivateBar)" do
        before { create(:vso, participant_id: poa_participant_id) }

        include_examples "new appeal has user-selected ScheduleHearingTask task"
        include_examples "new appeal has user-selected EvidenceSubmissionWindowTask task"
        include_examples "new appeal has user-selected TrackVeteranTask and IHPTask tasks"
        include_examples "new appeal does not have post-distribution tasks"
      end

      context "when given real task trees" do
        let(:source_appeal) do
          sji = SanitizedJsonImporter.from_file("spec/records/#{json_filename}", verbosity: 0)
          sji.import
          sji.imported_records[Appeal.table_name].first
        end
        before { create(:vso, participant_id: poa_participant_id) }

        context "Direct Review appeal with IHPTask, QualityReviewTask, IhpColocatedTask, TimedHoldTask" do
          let(:json_filename) do
            # Create an org needed to import the particular appeal
            Organization.create!(id: 212, name: "Some inactive org", url: "some_org", status: "inactive")
            "appeal-90772.json"
          end

          include_examples "new appeal has user-selected TrackVeteranTask and IHPTask tasks"
          include_examples "new appeal does not have post-distribution tasks"
        end
        context "Evidence Submission appeal with ESWTask, TranslationTask, SpecialCaseMovementTask, a MailTask" do
          let(:json_filename) { "appeal-140375.json" }

          include_examples "new appeal has user-selected EvidenceSubmissionWindowTask task"
          include_examples "new appeal does not have post-distribution tasks"
        end
        context "Hearing appeal with ESWTask, ScheduleHearingTask, HearingAdmin*Task, AssignHearingDispositionTask" do
          let(:json_filename) { "appeal-21430.json" }
          # There are multiple ESWTask and ScheduleHearingTask tasks, so just pick some
          let(:selected_task_ids) { [2_001_404_437, 2_001_413_151] }
          let(:source_esw_task) { Task.find(2_001_413_151) }

          include_examples "new appeal has user-selected EvidenceSubmissionWindowTask task"
          include_examples "new appeal does not have post-distribution tasks"
        end
      end
    end

    context "when source appeal is AOD" do
      context "source appeal is AOD due to claimant's age" do
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_age) }
        it "creates new appeal with AOD due to age" do
          expect(source_appeal.aod_based_on_age).to be true

          appellant_substitution = subject
          target_appeal = appellant_substitution.target_appeal
          expect(target_appeal.aod_based_on_age).to eq appellant_substitution.source_appeal.aod_based_on_age
        end
      end

      context "source appeal has non-age-related AOD Motion" do
        let(:source_appeal) { create(:appeal, :dispatched, :advanced_on_docket_due_to_motion) }
        # The original person associated with AOD may be the claimant or veteran; in this case, it is the claimant
        let(:aod_person) { source_appeal.claimant.person }
        it "copies AOD motions to new appeal" do
          expect(AdvanceOnDocketMotion.granted_for_person?(aod_person, source_appeal)).to be true
          expect(AdvanceOnDocketMotion.for_appeal(source_appeal).count).to eq 2
          aod_motions_count = AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, aod_person).count
          expect(source_appeal.aod?).to be true
          expect(source_appeal.cavc?).to be false

          appellant_substitution = subject
          # Source appeal's AODMotion are unchanged
          expect(AdvanceOnDocketMotion.for_appeal(source_appeal).count).to eq 2
          expect(AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, aod_person).count).to eq aod_motions_count
          expect(source_appeal.cavc?).to be false

          target_appeal = appellant_substitution.target_appeal
          # AODMotion are transferred to substitute claimant
          target_appeal_aod_person = target_appeal.claimant.person
          expect(AdvanceOnDocketMotion.for_appeal(target_appeal).count).to eq 1
          expect(AdvanceOnDocketMotion.for_appeal_and_person(target_appeal, target_appeal_aod_person).count).to eq 1
          expect(AdvanceOnDocketMotion.granted_for_person?(target_appeal.claimant.person, target_appeal)).to be true
          expect(target_appeal.aod?).to be true

          # InitialTasksFactory should not have auto-created EvidenceSubmissionWindowTask
          expect(EvidenceSubmissionWindowTask.where(appeal: target_appeal).count).to eq 0
        end
      end
      context "source appeal has CAVC status" do
        let(:source_appeal) { create(:appeal, :dispatched, :type_cavc_remand) }
        it "copies CAVC status to new appeal" do
          expect(source_appeal.cavc?).to be true

          appellant_substitution = subject
          # Source appeal's CAVC status is unchanged
          expect(source_appeal.cavc?).to be true

          target_appeal = appellant_substitution.target_appeal
          expect(target_appeal.cavc?).to be true

          # InitialTasksFactory should not have auto-created SendCavcRemandProcessedLetterTask
          expect(SendCavcRemandProcessedLetterTask.where(appeal: target_appeal).count).to eq 0
        end
      end
      context "source appeal has AOD and CAVC status" do
        let(:source_appeal) { create(:appeal, :dispatched, :type_cavc_remand, :advanced_on_docket_due_to_motion) }
        it "copies AOD and CAVC status to new appeal" do
          expect(source_appeal.aod?).to be true
          expect(source_appeal.cavc?).to be true

          appellant_substitution = subject
          # Source appeal's CAVC status is unchanged
          expect(source_appeal.cavc?).to be true

          target_appeal = appellant_substitution.target_appeal
          expect(target_appeal.cavc?).to be true
          expect(target_appeal.aod?).to be true

          # InitialTasksFactory should not have auto-created typical initial tasks
          expect(EvidenceSubmissionWindowTask.where(appeal: target_appeal).count).to eq 0
          expect(SendCavcRemandProcessedLetterTask.where(appeal: target_appeal).count).to eq 0
        end
      end

      context "source appeal has request issues" do
        let(:source_appeal) { create(:appeal, :active, :with_request_issues).reload }
        it "copies request issues but not decision issues to new appeal" do
          expect(source_appeal.request_issues.count).to be > 0

          appellant_substitution = subject
          target_appeal = appellant_substitution.target_appeal
          expect(target_appeal.request_issues.count).to eq source_appeal.request_issues.count
          expect(target_appeal.request_issues.pluck(:benefit_type))
            .to eq source_appeal.request_issues.pluck(:benefit_type)
          expect(target_appeal.request_issues.pluck(:contested_issue_description))
            .to eq source_appeal.request_issues.pluck(:contested_issue_description)
          expect(target_appeal.request_issues.pluck(:notes)).to eq source_appeal.request_issues.pluck(:notes)

          expect(target_appeal.decision_issues.count).to eq 0
          expect(target_appeal.request_issues.pluck(:decision_date).uniq).to eq [nil]
        end
      end
    end

    context "when missing required attributes" do
      context "for created_by" do
        let(:created_by) { nil }
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for source_appeal" do
        let(:source_appeal) { nil }
        let(:selected_task_ids) { [] }
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for created_by" do
        let(:created_by) { nil }
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for substitute" do
        let(:substitute) { nil }
        let(:poa_participant_id) { "11111" }
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for poa_participant_id" do
        let(:poa_participant_id) { nil }
        it "creates the appellant substitution successfully" do
          expect { subject }.not_to raise_error
          expect(subject.target_appeal.appellant_substitution).to eq subject
          expect(subject.target_appeal.appellant_substitution?).to eq true
        end
      end
    end
  end
end
