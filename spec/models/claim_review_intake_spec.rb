# frozen_string_literal: true

describe ClaimReviewIntake, :postgres do
  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:completed_at) { nil }
  let(:completion_started_at) { nil }

  let(:intake) do
    SupplementalClaimIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at,
      completion_started_at: completion_started_at
    )
  end

  context "#review!" do
    subject { intake.review!(params) }

    let(:receipt_date) { 1.day.ago }
    let(:benefit_type) { "compensation" }
    let(:claimant) { nil }
    let(:claimant_type) { "veteran" }
    let(:payee_code) { nil }
    let(:legacy_opt_in_approved) { false }

    let(:detail) do
      create(
        :supplemental_claim,
        benefit_type: nil,
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let(:params) do
      ActionController::Parameters.new(
        receipt_date: receipt_date,
        benefit_type: benefit_type,
        claimant: claimant,
        claimant_type: claimant_type,
        payee_code: payee_code,
        legacy_opt_in_approved: legacy_opt_in_approved
      )
    end

    context "Veteran is claimant" do
      it "adds veteran to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimant).to have_attributes(
          participant_id: intake.veteran.participant_id,
          payee_code: nil,
          decision_review: intake.detail,
          type: "VeteranClaimant"
        )
      end
    end

    context "Claimant is different than Veteran" do
      let(:claimant) { "1234" }
      let(:claimant_type) { "dependent" }
      let(:payee_code) { "10" }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimant).to have_attributes(
          participant_id: "1234",
          payee_code: "10",
          decision_review: intake.detail,
          type: "DependentClaimant"
        )
      end

      context "claimant is missing address" do
        let(:empty_address) { { address_line_1: nil, address_line_2: nil, city: nil, state: nil, zip: nil } }

        before do
          allow_any_instance_of(BgsAddressService).to receive(:fetch_bgs_record).and_return(empty_address)
        end

        it "adds claimant address required error" do
          expect(subject).to be_falsey
          expect(detail.errors[:claimant]).to include("claimant_address_required")
          expect(detail.claimants).to be_empty
        end

        context "when the benefit type is noncomp" do
          let(:benefit_type) { "education" }

          it "does not require address" do
            expect(subject).to be_truthy
            expect(intake.detail.claimants.count).to eq 1
            expect(intake.detail.claimant).to have_attributes(
              participant_id: "1234",
              payee_code: nil,
              decision_review: intake.detail
            )
          end
        end
      end

      context "claimant is nil" do
        let(:claimant) { nil }
        let(:receipt_date) { 3.days.from_now }

        it "is expected to add an error that claimant cannot be blank" do
          expect(subject).to be_falsey
          expect(detail.errors[:claimant]).to include("blank")
          expect(detail.errors[:receipt_date]).to include("in_future")
          expect(detail.claimants).to be_empty
        end
      end

      context "And payee code is nil" do
        let(:payee_code) { nil }
        # Check that the decision_review validations still work
        let(:receipt_date) { 3.days.from_now }

        context "And benefit type is compensation" do
          let(:benefit_type) { "compensation" }

          it "is expected to add an error that payee_code cannot be blank" do
            expect(subject).to eq(false)
            expect(detail.errors[:payee_code]).to include("blank")
            expect(detail.errors[:receipt_date]).to include("in_future")
            expect(detail.claimants).to be_empty
          end
        end

        context "And benefit type is pension" do
          let(:benefit_type) { "pension" }

          it "is expected to add an error that payee_code cannot be blank" do
            expect(subject).to be_falsey
            expect(detail.errors[:payee_code]).to include("blank")
            expect(detail.errors[:receipt_date]).to include("in_future")
            expect(detail.claimants).to be_empty
          end
        end

        context "And benefit type is fiduciary" do
          let(:benefit_type) { "fiduciary" }

          it "is expected to add an error that payee_code cannot be blank" do
            expect(subject).to be_falsey
            expect(detail.errors[:payee_code]).to include("blank")
            expect(detail.errors[:receipt_date]).to include("in_future")
            expect(detail.claimants).to be_empty
          end
        end
      end

      context "And benefit type is not compensation, pension, or fiduciary" do
        let(:benefit_type) { "insurance" }

        it "sets payee_code to nil" do
          subject

          expect(intake.detail.claimants.count).to eq 1
          expect(intake.detail.claimant).to have_attributes(
            participant_id: "1234",
            payee_code: nil,
            decision_review: intake.detail
          )
        end
      end
    end
  end
end
