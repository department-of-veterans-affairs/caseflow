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
        poa_participant_id: poa_participant_id
      }
    end

    it "creates the record" do
      expect { subject }.not_to raise_error
      params.each_key { |key| expect(subject.send(key)).to eq params[key] }

      expect(subject.target_appeal.docket_number).to eq subject.source_appeal.docket_number
      expect(subject.substitute_claimant).to eq subject.target_appeal.claimant
      expect(subject.substitute_person).to eq subject.target_appeal.claimant.person
      expect(subject.substitute_person).not_to eq subject.source_appeal.claimant.person
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
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_motion) }
        # The original person associated with AOD may be the claimant or veteran; in this case, it is the claimant
        let(:aod_person) { source_appeal.claimant.person }
        it "copies AOD motions to new appeal" do
          expect(AdvanceOnDocketMotion.granted_for_person?(aod_person, source_appeal)).to be true
          expect(AdvanceOnDocketMotion.for_appeal(source_appeal).count).to eq 2
          aod_motions_count = AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, aod_person).count
          expect(source_appeal.aod?).to be true

          appellant_substitution = subject
          # Source appeal's AODMotion are unchanged
          expect(AdvanceOnDocketMotion.for_appeal(source_appeal).count).to eq 2
          expect(AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, aod_person).count).to eq aod_motions_count

          target_appeal = appellant_substitution.target_appeal
          # AODMotion are transferred to substitute claimant
          target_appeal_aod_person = target_appeal.claimant.person
          expect(AdvanceOnDocketMotion.for_appeal(target_appeal).count).to eq 1
          expect(AdvanceOnDocketMotion.for_appeal_and_person(target_appeal, target_appeal_aod_person).count).to eq 1
          expect(AdvanceOnDocketMotion.granted_for_person?(target_appeal.claimant.person, target_appeal)).to be true
          expect(target_appeal.aod?).to be true
        end
      end
      context "source appeal has request issues" do
        let(:source_appeal) { create(:appeal, :active, :with_request_issues) }
        it "copies request issues but not decision issues to new appeal" do
          expect(source_appeal.request_issues.count).to be > 0

          appellant_substitution = subject
          target_appeal = appellant_substitution.target_appeal
          expect(target_appeal.request_issues.count).to eq source_appeal.request_issues.count
          expect(target_appeal.decision_issues.count).to eq 0
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
