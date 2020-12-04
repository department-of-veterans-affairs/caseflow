# frozen_string_literal: true

describe LegacyAppealRepresentative do
  let(:participant_id) { "1122334455" }
  let(:vacols_case) { create(:case) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:poa) { double("PowerOfAttorney") }
  let!(:lar) { LegacyAppealRepresentative.new(power_of_attorney: poa, case_record: vacols_case) }
  let!(:representative) { create(:vso, participant_id: participant_id) }

  before do
    allow(poa).to receive(:bgs_participant_id).and_return(participant_id)
    allow(appeal).to receive(:legacy_appeal_representative).and_return(lar)
  end

  describe "representatives" do
    it "returns the representative with matching participant id" do
      expect(lar.representatives.count).to eq 1
      expect(lar.representatives).to include representative
    end

    context "no representative_participant_id" do
      before { allow(poa).to receive(:bgs_participant_id).and_return(nil) }

      it "returns an empty association" do
        expect(lar.representatives.count).to eq 0
      end

      # necessary because there are Representative records in production
      # with nil participant ids
      context "there's a representative with a nil participant id" do
        let(:participant_id) { nil }

        it "returns an empty association" do
          expect(Representative.where(participant_id: nil).count).to eq 1
          expect(lar.representatives.count).to eq 0
        end
      end
    end
  end

  describe "representative_is_vso?" do
    context "representative is a vso" do
      it "is true" do
        expect(lar.representative_is_vso?).to eq true
      end

      context "no representative_participant_id" do
        before { allow(poa).to receive(:bgs_participant_id).and_return(nil) }

        # necessary because there are Representative records in production
        # with nil participant ids
        context "there's a vso representative with a nil participant id" do
          let(:participant_id) { nil }

          it "is false" do
            expect(Representative.where(participant_id: nil).count).to eq 1
            expect(lar.representative_is_vso?).to eq false
          end
        end
      end
    end

    context "representative is not a vso" do
      let(:representative) { create(:private_bar, participant_id: participant_id) }

      it "is false" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_vso?).to eq false
      end
    end
  end

  describe "representative_is_colocated_vso?" do
    context "representative is a colocated vso" do
      it "is true" do
        expect(lar.representative_is_colocated_vso?).to eq true
      end
    end

    context "representative is not a colocated vso" do
      let(:representative) { create(:field_vso, participant_id: participant_id) }

      it "is false" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_colocated_vso?).to eq false
      end
    end

    context "representative is not a vso" do
      let(:representative) { create(:private_bar, participant_id: participant_id) }

      it "is false" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_colocated_vso?).to eq false
      end
    end
  end

  describe "representative_is_agent?" do
    before do
      # poa is returned from bgs in application, let's use poa from bgs
      RequestStore.store[:application] = "hearings"
      allow(poa).to receive(:bgs_representative_type).and_return(poa_type)
    end

    let(:poa_type) { nil }

    context "representative is a agent" do
      let(:poa_type) { "Agent" }

      it "is true" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_agent?).to eq true
      end
    end

    context "representative is a private attorney" do
      let(:poa_type) { "Attorney" }

      it "is true" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_agent?).to eq true
      end
    end

    context "representative is a colocated vso" do
      it "is false" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_agent?).to eq false
      end
    end
  end

  describe "representative_is_organization?" do
    before do
      # poa is returned from bgs in application, let's use poa from bgs
      RequestStore.store[:application] = "hearings"
      allow(poa).to receive(:bgs_representative_type).and_return(poa_type)
    end

    let(:poa_type) { nil }

    context "representative is organization" do
      let(:poa_type) { "Service Organization" }

      it "is true" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_organization?).to eq true
      end
    end

    context "representative is a private attorney" do
      let(:poa_type) { "Attorney" }

      it "is false" do
        expect(lar.representatives.count).to eq 1
        expect(lar.representative_is_organization?).to eq false
      end
    end
  end
end
