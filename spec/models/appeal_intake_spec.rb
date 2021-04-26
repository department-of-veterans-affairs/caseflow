# frozen_string_literal: true

describe AppealIntake, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:completed_at) { nil }

  let(:intake) do
    AppealIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  let(:profile_date) { Time.zone.local(2018, 9, 15) }

  let!(:rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: profile_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "reference-id", decision_text: "Left knee granted" }
      ]
    )
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) { create(:appeal, veteran_file_number: veteran_file_number, receipt_date: 3.days.ago) }

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
        contested_rating_issue_profile_date: Time.zone.local(2018, 4, 30),
        contested_rating_issue_reference_id: "issue1",
        contested_issue_description: "description",
        contention_reference_id: "1234"
      )
    end

    it "cancels and deletes the Appeal record created" do
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

  context "#review!" do
    subject { intake.review!(request_params) }

    let(:receipt_date) { "2018-05-25" }
    let(:docket_type) { Constants.AMA_DOCKETS.hearing }
    let(:claimant) { nil }
    let(:claimant_type) { "veteran" }
    let(:claimant_notes) { nil }
    let(:payee_code) { nil }
    let(:legacy_opt_in_approved) { true }

    let(:detail) { Appeal.create!(veteran_file_number: veteran_file_number) }

    let(:request_params) do
      ActionController::Parameters.new(
        receipt_date: receipt_date,
        docket_type: docket_type,
        claimant: claimant,
        claimant_type: claimant_type,
        claimant_notes: claimant_notes,
        payee_code: payee_code,
        legacy_opt_in_approved: legacy_opt_in_approved
      )
    end

    it "updates appeal with values" do
      expect(subject).to be_truthy

      expect(intake.detail).to have_attributes(
        receipt_date: Date.new(2018, 5, 25),
        docket_type: Constants.AMA_DOCKETS.hearing,
        legacy_opt_in_approved: true,
        veteran_is_not_claimant: false
      )
    end

    it "adds veteran to claimants" do
      expect(subject).to be_truthy

      expect(intake.detail.claimants.count).to eq 1
      expect(intake.detail.claimant).to have_attributes(
        participant_id: intake.veteran.participant_id,
        payee_code: nil,
        decision_review: intake.detail,
        type: "VeteranClaimant"
      )
    end

    context "when claimant is unlisted non-veteran" do
      before { FeatureToggle.enable!(:non_veteran_claimants) }
      after { FeatureToggle.disable!(:non_veteran_claimants) }

      let(:request_params) do
        ActionController::Parameters.new(
          receipt_date: receipt_date,
          docket_type: docket_type,
          claimant: nil,
          claimant_type: "other",
          payee_code: payee_code,
          legacy_opt_in_approved: legacy_opt_in_approved,
          unlisted_claimant: {
            relationship: "child",
            party_type: "individual",
            first_name: "John",
            last_name: "Smith",
            address_line_1: "1600 Pennsylvania Ave",
            city: "Springfield",
            state: "NY",
            zip: "12345",
            country: "USA",
            poa_form: false
          }
        )
      end

      it "adds unlisted claimant and saves additional details" do
        expect(subject).to be_truthy
        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimant).to have_attributes(
          participant_id: intake.veteran.participant_id,
          payee_code: nil,
          decision_review: intake.detail,
          type: "OtherClaimant",
          name: "John Smith",
          relationship: "Child"
        )
      end
    end

    context "receipt date is blank" do
      let(:receipt_date) { nil }

      it { is_expected.to be_falsey }
    end

    context "docket type is blank" do
      let(:docket_type) { nil }

      it { is_expected.to be_falsey }
    end

    context "Claimant has notes saved" do
      let(:claimant_notes) { "This is a claimant note" }
      let(:request_params) do
        ActionController::Parameters.new(
          receipt_date: receipt_date,
          docket_type: docket_type,
          claimant: claimant,
          claimant_type: claimant_type,
          payee_code: payee_code,
          legacy_opt_in_approved: legacy_opt_in_approved,
          claimant_notes: claimant_notes
        )
      end

      it "adds note to unlisted claimants" do
        subject
        expect(intake.detail.claimant).to have_attributes(
          payee_code: nil,
          decision_review: intake.detail,
          notes: "This is a claimant note"
        )
      end
    end

    context "Claimant is different than Veteran" do
      let(:claimant) { "1234" }
      let(:payee_code) { "10" }
      let(:claimant_type) { "dependent" }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimant).to have_attributes(
          participant_id: "1234",
          payee_code: nil,
          decision_review: intake.detail,
          type: "DependentClaimant"
        )
      end

      context "claimant is missing address" do
        before do
          allow_any_instance_of(BgsAddressService).to receive(:address).and_return(nil)
        end

        it "does not require the address" do
          expect(subject).to be_truthy
          expect(intake.detail.claimants.count).to eq 1
          expect(intake.detail.claimant).to have_attributes(
            participant_id: "1234",
            payee_code: nil,
            decision_review: intake.detail
          )
        end
      end

      context "claimant is nil" do
        let(:claimant) { nil }

        it "is expected to add an error that claimant cannot be blank" do
          expect(subject).to be_falsey
          expect(detail.errors[:claimant]).to include("blank")
          expect(detail.claimants).to be_empty
        end
      end

      context "claimant is attorney" do
        let(:claimant_type) { "attorney" }

        it "sets correct claimant type" do
          expect(subject).to be_truthy
          expect(intake.detail.claimant).to have_attributes(type: "AttorneyClaimant")
        end
      end

      context "claimant is other" do
        let(:claimant_type) { "other" }
        let(:claimant) { nil }

        context "when notes are set" do
          let(:claimant_notes) { "foo" }

          it "sets correct claimant type" do
            expect(subject).to be_truthy
            expect(intake.detail.claimant).to have_attributes(
              type: "OtherClaimant",
              notes: claimant_notes
            )
          end
        end
      end
    end

    context "receipt date is in the future" do
      let(:receipt_date) { 3.days.from_now }

      it "is invalid" do
        expect(subject).to be_falsey
        expect(detail.errors[:receipt_date]).to include("in_future")
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:legacy_opt_in_approved) { false }

    let(:params) { { request_issues: issue_data } }

    let(:issue_data) do
      [
        {
          rating_issue_reference_id: "reference-id",
          decision_text: "decision text"
        },
        { decision_text: "nonrating request issue decision text",
          nonrating_issue_category: "test issue category",
          benefit_type: "compensation",
          decision_date: "2018-12-25" }
      ]
    end

    let(:detail) do
      Appeal.create!(
        veteran_file_number: veteran_file_number,
        receipt_date: 3.days.ago,
        legacy_opt_in_approved: legacy_opt_in_approved,
        docket_type: Constants.AMA_DOCKETS.direct_review
      )
    end

    it "completes the intake" do
      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
      expect(intake.detail.request_issues.count).to eq 2
      expect(intake.detail.target_decision_date).to_not be_nil
      expect(intake.detail.request_issues.first).to have_attributes(
        contested_rating_issue_reference_id: "reference-id",
        contested_issue_description: "decision text"
      )
      expect(intake.detail.request_issues.second).to have_attributes(
        nonrating_issue_category: "test issue category",
        decision_date: Date.new(2018, 12, 25),
        nonrating_issue_description: "nonrating request issue decision text"
      )
      expect(intake.detail.tasks.count).to eq 2
      expect(intake.detail.submitted?).to eq true
      expect(intake.detail.attempted?).to eq true
      expect(intake.detail.processed?).to eq true
    end

    context "when a legacy VACOLS opt-in occurs" do
      let(:vacols_issue) { create(:case_issue) }
      let(:vacols_case) { create(:case, case_issues: [vacols_issue]) }
      let(:legacy_appeal) do
        create(:legacy_appeal, vacols_case: vacols_case)
      end

      let(:issue_data) do
        [
          {
            profile_date: "2018-04-30",
            rating_issue_reference_id: "reference-id",
            decision_text: "decision text",
            vacols_id: legacy_appeal.vacols_id,
            vacols_sequence_id: vacols_issue.issseq
          }
        ]
      end

      context "legacy_opt_in_approved is false" do
        it "does not submit a LegacyIssueOptin" do
          expect(LegacyIssueOptin.count).to eq 0

          subject

          expect(LegacyIssueOptin.count).to eq 0
        end
      end

      context "legacy_opt_approved is true" do
        let(:legacy_opt_in_approved) { true }

        it "submits a LegacyIssueOptin" do
          expect(LegacyIssueOptin.count).to eq 0
          expect_any_instance_of(LegacyOptinManager).to receive(:process!).once

          subject

          expect(LegacyIssueOptin.count).to eq 1
        end
      end
    end
  end
end
