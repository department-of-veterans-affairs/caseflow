# frozen_string_literal: true

describe GrantedSubstitution do
  describe ".create!" do
    subject { GrantedSubstitution.create!(params) }

    let(:created_by) { create(:user) }
    let(:source_appeal) { create(:appeal) }
    let(:substitution_date) { 5.days.ago.to_date }
    let(:substitute) { create(:claimant) }
    let(:poa_participant_id) { "100" }

    let(:params) do
      {
        created_by: created_by,
        source_appeal: source_appeal,
        substitution_date: substitution_date,
        substitute_id: substitute&.id,
        poa_participant_id: poa_participant_id
      }
    end

    it "creates the record" do
      expect { subject }.not_to raise_error
      params.each_key { |key| expect(subject.send(key)).to eq params[key] }
    end

    context "when source appeal is AOD" do
      context "source appeal is AOD due to claimant's age" do
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_age) }
        it "creates new CAVC remand appeal with AOD due to age" do
          expect(source_appeal.aod_based_on_age).to be true

          cavc_remand = subject
          cavc_appeal = cavc_remand.target_appeal
          expect(cavc_appeal.aod_based_on_age).to eq cavc_remand.source_appeal.aod_based_on_age
        end
      end
      context "source appeal has non-age-related AOD Motion" do
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_motion) }
        it "copies AOD motions to new CAVC remand appeal" do
          person = source_appeal.claimant.person
          expect(AdvanceOnDocketMotion.granted_for_person?(person, source_appeal)).to be true
          aod_motions_count = AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, person).count
          expect(source_appeal.aod?).to be true

          cavc_remand = subject
          cavc_appeal = cavc_remand.target_appeal
          expect(cavc_remand.source_appeal.claimant.person).to eq person
          expect(cavc_appeal.claimant.person).to eq person
          expect(AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, person).count).to eq aod_motions_count
          expect(AdvanceOnDocketMotion.for_appeal_and_person(cavc_appeal, person).count).to eq aod_motions_count

          expect(AdvanceOnDocketMotion.granted_for_person?(cavc_appeal.claimant.person, cavc_appeal)).to be true
          expect(cavc_appeal.aod?).to be true
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
