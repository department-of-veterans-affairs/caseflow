# frozen_string_literal: true

describe AppellantSubstitution do
  describe ".create!" do
    subject { described_class.create!(params) }

    let(:created_by) { create(:user) }
    let(:source_appeal) { create(:appeal) }
    let(:substitution_date) { 5.days.ago.to_date }
    let(:substitute) { create(:claimant) }
    let(:poa_participant_id) { "13579" }

    let(:params) do
      {
        created_by: created_by,
        source_appeal: source_appeal,
        substitution_date: substitution_date,
        claimant_type: substitute&.type,
        substitute_participant_id: substitute&.participant_id,
        poa_participant_id: poa_participant_id,
        selected_task_ids: [],
        task_params: {}
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
      expect(subject.target_appeal.tasks.open.map(&:type)).to include "DistributionTask"
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
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for poa_participant_id" do
        let(:poa_participant_id) { nil }
        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
