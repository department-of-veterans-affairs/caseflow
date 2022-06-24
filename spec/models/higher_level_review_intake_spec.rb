# frozen_string_literal: true

require "./spec/support/shared_context/shared_context_legacy_appeal.rb"
require "./spec/support/shared_context/shared_context_intake.rb"

describe HigherLevelReviewIntake, :all_dbs do
  before do
    Time.zone = "Eastern Time (US & Canada)"
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:completed_at) { nil }
  let(:completion_started_at) { nil }

  let(:intake) do
    HigherLevelReviewIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at,
      completion_started_at: completion_started_at
    )
  end

  context "#start!" do
    subject { intake.start! }

    let!(:active_epe) do
      create(
        :end_product_establishment,
        :active,
        veteran_file_number: veteran_file_number,
        established_at: Time.zone.yesterday
      )
    end

    let!(:canceled_epe) do
      create(
        :end_product_establishment,
        :canceled,
        veteran_file_number: veteran_file_number,
        established_at: Time.zone.yesterday
      )
    end

    before do
      @synced = []
      allow_any_instance_of(EndProductEstablishment).to receive(:sync_source!) do |epe|
        @synced << epe.id
      end
    end

    it "syncs all active EPEs" do
      subject

      expect(@synced).to eq [active_epe.id]
    end
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let!(:claimant) do
      DependentClaimant.create!(
        decision_review: detail,
        participant_id: "1234",
        payee_code: "10"
      )
    end

    let!(:request_issue) do
      RequestIssue.new(
        decision_review: detail,
        contested_rating_issue_profile_date: Time.zone.local(2018, 4, 5),
        contested_rating_issue_reference_id: "issue1",
        contested_issue_description: "description",
        contention_reference_id: "1234"
      )
    end

    it "cancels and deletes the Higher-Level Review record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
      expect { claimant.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { request_issue.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    before do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    end

    let(:issue_data) do
      {
        rating_issue_reference_id: "reference-id",
        decision_text: "decision text"
      }
    end

    let(:params) { { request_issues: [issue_data] } }

    let(:legacy_opt_in_approved) { false }
    let(:benefit_type) { "compensation" }

    let(:detail) do
      create(
        :higher_level_review,
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago,
        legacy_opt_in_approved: legacy_opt_in_approved,
        benefit_type: benefit_type,
        veteran_is_not_claimant: false
      )
    end

    let!(:claimant) do
      VeteranClaimant.create!(
        decision_review: detail,
        participant_id: veteran.participant_id,
        payee_code: "00"
      )
    end

    let(:ratings_end_product_establishment) do
      EndProductEstablishment.find_by(source: intake.reload.detail, code: "030HLRR")
    end

    it "completes the intake and performs all necessary VBMS actions" do
      subject

      expect(intake).to be_success
      expect(intake.detail.establishment_submitted_at).to eq(Time.zone.now)
      expect(ratings_end_product_establishment).to_not be_nil
      expect(ratings_end_product_establishment.established_at).to eq(Time.zone.now)

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: hash_including(
          benefit_type_code: "1",
          payee_code: "00",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: user.station_id,
          date: detail.receipt_date.to_date,
          end_product_modifier: "030",
          end_product_label: "Higher-Level Review Rating",
          end_product_code: "030HLRR",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: veteran.participant_id
        ),
        veteran_hash: intake.veteran.to_vbms_hash,
        user: user
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: intake.detail.veteran_file_number,
        claim_id: ratings_end_product_establishment.reference_id,
        contentions: array_including(description: "decision text",
                                     contention_type: Constants.CONTENTION_TYPES.higher_level_review),
        user: user,
        claim_date: detail.receipt_date.to_date
      )

      expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
        claim_id: ratings_end_product_establishment.reference_id,
        rating_issue_contention_map: {
          "reference-id" => intake.detail.request_issues.first.contention_reference_id
        }
      )

      expect(intake.detail.request_issues.count).to eq 1
      expect(intake.detail.request_issues.first).to have_attributes(
        contested_rating_issue_reference_id: "reference-id",
        contested_issue_description: "decision text",
        rating_issue_associated_at: Time.zone.now
      )
    end

    context "when disable_claim_establishment is enabled" do
      before { FeatureToggle.enable!(:disable_claim_establishment) }
      after { FeatureToggle.disable!(:disable_claim_establishment) }

      it "does not submit claims to VBMS" do
        subject

        expect(intake).to be_success
        expect(intake.detail.establishment_submitted_at).to eq(Time.zone.now)
        expect(ratings_end_product_establishment).to_not be_nil
        expect(ratings_end_product_establishment.established_at).to eq(nil)
        expect(Fakes::VBMSService).not_to have_received(:establish_claim!)
        expect(Fakes::VBMSService).not_to have_received(:create_contentions!)
        expect(Fakes::VBMSService).not_to have_received(:associate_rating_request_issues!)
        expect(intake.detail.request_issues.count).to eq 1
        expect(intake.detail.request_issues.first).to have_attributes(
          contested_rating_issue_reference_id: "reference-id",
          contested_issue_description: "decision text",
          rating_issue_associated_at: nil
        )
        expect(HigherLevelReview.processable.count).to eq 1
      end
    end

    context "when benefit type is pension" do
      let(:benefit_type) { "pension" }
      let(:pension_rating_ep_establishment) do
        EndProductEstablishment.find_by(source: intake.reload.detail, code: "030HLRRPMC")
      end

      it "completes the intake with pension ep code" do
        subject

        expect(pension_rating_ep_establishment).to_not be_nil
        expect(pension_rating_ep_establishment.established_at).to eq(Time.zone.now)

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          hash_including(claim_hash: hash_including(end_product_code: "030HLRRPMC"))
        )
      end
    end
    
    include_context "intake", include_shared: true

    context "when the intake is pending" do
      let(:completion_started_at) { Time.zone.now }

      it "does nothing" do
        subject

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end

  include_context "completed intake", include_shared: true
  end
end
