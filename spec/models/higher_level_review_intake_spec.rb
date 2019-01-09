describe HigherLevelReviewIntake do
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

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let!(:claimant) do
      Claimant.create!(
        review_request: detail,
        participant_id: "1234",
        payee_code: "10"
      )
    end

    let!(:request_issue) do
      RequestIssue.new(
        review_request: detail,
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

  context "#review!" do
    subject { intake.review!(params) }

    let(:receipt_date) { 1.day.ago }
    let(:benefit_type) { "compensation" }
    let(:informal_conference) { false }
    let(:same_office) { false }
    let(:claimant) { nil }
    let(:payee_code) { nil }
    let(:veteran_is_not_claimant) { false }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let(:params) do
      ActionController::Parameters.new(
        receipt_date: receipt_date,
        benefit_type: benefit_type,
        informal_conference: informal_conference,
        same_office: same_office,
        claimant: claimant,
        payee_code: payee_code,
        veteran_is_not_claimant: veteran_is_not_claimant
      )
    end

    context "Veteran is claimant" do
      it "adds veteran to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: intake.veteran.participant_id,
          payee_code: nil
        )
      end
    end

    context "Claimant is different than Veteran" do
      let(:claimant) { "1234" }
      let(:payee_code) { "10" }
      let(:veteran_is_not_claimant) { true }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: "1234",
          payee_code: "10"
        )
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
        # Check that the review_request validations still work
        let(:receipt_date) { 3.days.from_now }

        context "And benefit type is compensation" do
          let(:benefit_type) { "compensation" }

          it "is expected to add an error that payee_code cannot be blank" do
            expect(subject).to be_falsey
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
      end

      context "And benefit type is not compensation or pension" do
        let(:benefit_type) { "fiduciary" }

        it "sets payee_code to nil" do
          subject

          expect(intake.detail.claimants.count).to eq 1
          expect(intake.detail.claimants.first).to have_attributes(
            participant_id: "1234",
            payee_code: nil
          )
        end
      end
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
        benefit_type: benefit_type
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
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "00",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "499",
          date: detail.receipt_date.to_date,
          end_product_modifier: "030",
          end_product_label: "Higher-Level Review Rating",
          end_product_code: "030HLRR",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: nil
        },
        veteran_hash: intake.veteran.to_vbms_hash,
        user: user
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: intake.detail.veteran_file_number,
        claim_id: ratings_end_product_establishment.reference_id,
        contentions: [{ description: "decision text" }],
        user: user
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

    context "when benefit type is non comp" do
      let(:benefit_type) { "fiduciary" }

      it "creates DecisionReviewTask" do
        subject

        intake.detail.reload

        expect(intake.detail.tasks.count).to eq(1)
        expect(intake.detail.tasks.first).to be_a(DecisionReviewTask)
      end
    end

    context "when a legacy VACOLS opt-in occurs" do
      let(:vacols_issue) { create(:case_issue) }
      let(:vacols_case) { create(:case, case_issues: [vacols_issue]) }
      let(:legacy_appeal) do
        create(:legacy_appeal, vacols_case: vacols_case)
      end

      let(:issue_data) do
        {
          profile_date: "2018-04-30T11:11:00.000-04:00",
          reference_id: "reference-id",
          decision_text: "decision text",
          vacols_id: legacy_appeal.vacols_id,
          vacols_sequence_id: vacols_issue.issseq
        }
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

    context "when the intake was already complete" do
      let(:completed_at) { Time.zone.now }

      it "does nothing" do
        subject

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end

    context "when the intake is pending" do
      let(:completion_started_at) { Time.zone.now }

      it "does nothing" do
        subject

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end

    context "when end product creation fails" do
      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end

      it "clears pending status" do
        allow(detail).to receive(:establish!).and_raise(unknown_error)

        expect { subject }.to raise_exception(unknown_error)
        expect(intake.completion_status).to be_nil
      end
    end
  end
end
