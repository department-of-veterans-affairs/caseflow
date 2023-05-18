# frozen_string_literal: true

describe Idt::V1::AppealDetailsSerializer, :postgres do
  let(:appeal) { create(:appeal, veteran_is_not_claimant: true) }
  let(:include_addresses) { true }
  let(:base_url) { "va.gov" }
  let(:params) { { include_addresses: include_addresses, base_url: base_url } }

  subject { described_class.new(appeal, params: params) }

  context "badges attribute" do
    subject { described_class.new(appeal, params: params).serializable_hash[:data][:attributes][:badges] }

    context "legacy appeals " do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "returns nil for legacy appeals" do
        expect(subject).to be nil
      end
    end

    context "ama appeals" do
      it "does not return nil for ama appeals" do
        expect(subject).to_not be nil
      end

      it "returns object with false default values" do
        expect(subject[:contested_claim]).to be false
        expect(subject[:fnod]).to be false
        expect(subject[:hearing]).to be false
        expect(subject[:overtime]).to be false
      end

      context "contested claims" do
        before { FeatureToggle.enable!(:indicator_for_contested_claims) }
        after { FeatureToggle.disable!(:indicator_for_contested_claims) }

        let(:appeal) { create(:appeal, request_issues: request_issues) }
        let(:request_issues) do
          [
            create(
              :request_issue,
              benefit_type: "compensation",
              nonrating_issue_category: "Contested Claims - Insurance"
            )
          ]
        end

        it "sets contested claim key value to true" do
          expect(subject[:contested_claim]).to be true
          expect(subject[:fnod]).to be false
          expect(subject[:hearing]).to be false
          expect(subject[:overtime]).to be false
        end
      end

      context "overtime" do
        before do
          FeatureToggle.enable!(:overtime_revamp)
          appeal.overtime = true
        end
        after { FeatureToggle.disable!(:overtime_revamp) }

        it "sets overtime key value to true" do
          expect(subject[:contested_claim]).to be false
          expect(subject[:fnod]).to be false
          expect(subject[:hearing]).to be false
          expect(subject[:overtime]).to be true
        end
      end

      context "fnod" do
        before do
          veteran.update!(date_of_death: date_of_death)
          FeatureToggle.enable!(:view_fnod_badge_in_hearings)
        end
        after { FeatureToggle.disable!(:view_fnod_badge_in_hearings) }
        let(:veteran) { create(:veteran) }
        let(:appeal) { create(:appeal, veteran: veteran) }
        let(:date_of_death) { Time.zone.today - 1.year }

        it "sets fnod key value to true" do
          expect(subject[:contested_claim]).to be false
          expect(subject[:fnod]).to be true
          expect(subject[:hearing]).to be false
          expect(subject[:overtime]).to be false
        end
      end

      context "hearing" do
        let!(:attorney_task_with_hearing) do
          create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: create(:user)
          )
        end
        let(:appeal) { attorney_task_with_hearing.appeal }
        let!(:hearing) do
          create(
            :hearing,
            appeal: attorney_task_with_hearing.appeal,
            disposition: "held"
          )
        end

        it "sets both fnod and hearing key values to true" do
          expect(subject[:contested_claim]).to be false
          expect(subject[:fnod]).to be false
          expect(subject[:hearing]).to be true
          expect(subject[:overtime]).to be false
        end
      end
    end
  end

  context "Appellant data" do
    it "includes address_line_3" do
      serialized_attributes = subject.serializable_hash[:data][:attributes]

      claimant_attributes = serialized_attributes[:appellants].first
      expect(claimant_attributes[:address][:address_line_3]).to_not be nil
    end

    it "does not populate full_name when last name is present" do
      serialized_attributes = subject.serializable_hash[:data][:attributes]
      claimant_attributes = serialized_attributes[:appellants].first

      expect(claimant_attributes[:last_name]).to_not be nil
      expect(claimant_attributes[:full_name]).to be nil
    end

    it "includes the name suffix if present" do
      allow_any_instance_of(Claimant).to receive(:suffix).and_return("PhD")

      serialized_attributes = subject.serializable_hash[:data][:attributes]

      claimant_attributes = serialized_attributes[:appellants].first
      expect(claimant_attributes[:name_suffix]).to eq "PhD"
    end

    context "when the claimant is missing last name, but has full name" do
      it "populates full name in appellant attributes" do
        allow_any_instance_of(Claimant).to receive(:name).and_return("Full Name")
        allow_any_instance_of(Claimant).to receive(:last_name).and_return(nil)

        serialized_attributes = subject.serializable_hash[:data][:attributes]
        claimant_attributes = serialized_attributes[:appellants].first

        expect(claimant_attributes[:last_name]).to be nil
        expect(claimant_attributes[:full_name]).to eq "Full Name".upcase
      end
    end
  end
end
