# frozen_string_literal: true

describe RampRefilingIntake, :postgres do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:detail) { nil }

  let(:intake) do
    RampRefilingIntake.new(
      user: user,
      veteran_file_number: veteran_file_number,
      detail: detail
    )
  end

  let(:completed_ramp_election_ep) do
    Generators::EndProduct.build(
      veteran_file_number: veteran_file_number,
      bgs_attrs: { status_type_code: "CLR" }
    )
  end

  let(:completed_ramp_election) do
    re = create(:ramp_election,
                veteran_file_number: veteran_file_number,
                notice_date: 4.days.ago,
                receipt_date: 3.days.ago,
                established_at: Time.zone.now)

    create(
      :end_product_establishment,
      source: re,
      established_at: Time.zone.now,
      veteran_file_number: veteran_file_number,
      reference_id: completed_ramp_election_ep.claim_id,
      synced_status: "CLR"
    )

    re
  end

  let(:second_completed_ramp_election) do
    re = create(:ramp_election,
                veteran_file_number: veteran_file_number,
                notice_date: 2.days.ago,
                receipt_date: 1.day.ago,
                established_at: Time.zone.now)
    ep = Generators::EndProduct.build(
      veteran_file_number: veteran_file_number,
      bgs_attrs: { status_type_code: "CLR" }
    )
    create(
      :end_product_establishment,
      source: re,
      established_at: Time.zone.now,
      veteran_file_number: veteran_file_number,
      reference_id: ep.claim_id,
      synced_status: "CLR"
    )
    re
  end

  let(:claim_id) { EndProductEstablishment.find_by(source: completed_ramp_election).reference_id }

  let(:ramp_election_contentions) do
    [Generators::Contention.build(claim_id: claim_id, text: "Left knee")]
  end

  context "#ui_hash" do
    subject { intake.ui_hash }

    let!(:ramp_election) do
      completed_ramp_election
    end

    let!(:ramp_election_contentions) do
      [Generators::Contention.build(claim_id: completed_ramp_election_ep.claim_id, text: "Left knee")]
    end

    let!(:pending_ramp_election) do
      create(:ramp_election,
             veteran_file_number: veteran_file_number,
             notice_date: 4.days.ago,
             established_at: Time.zone.now)
    end

    let!(:pending_ramp_election_contentions) do
      [Generators::Contention.build(claim_id: pending_end_product.claim_id, text: "Not me!")]
    end

    let!(:pending_end_product) do
      Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: { status_type_code: "PEND" }
      )
    end

    let!(:pending_end_product_establishment) do
      create(
        :end_product_establishment,
        veteran_file_number: veteran_file_number,
        source: pending_ramp_election,
        reference_id: pending_end_product.claim_id,
        established_at: Time.zone.now,
        synced_status: "PEND"
      )
    end

    let(:detail) do
      RampRefiling.create!(
        veteran_file_number: veteran_file_number,
        receipt_date: 10.seconds.ago,
        option_selected: "supplemental_claim"
      )
    end

    before do
      ramp_election.recreate_issues_from_contentions!
      pending_ramp_election.recreate_issues_from_contentions!
    end

    it "only returns issues for RAMP elections with completed decisions" do
      expect(subject[:issues].count).to eq(1)
      expect(subject[:issues].first[:description]).to eq("Left knee")
    end
  end

  context "#start!" do
    subject { intake.start! }

    context "valid to start" do
      let!(:ramp_election) { completed_ramp_election }
      let!(:contentions) { ramp_election_contentions }

      it "saves intake and sets detail to ramp election and loads issues" do
        expect(subject).to be_truthy

        expect(intake.started_at).to eq(Time.zone.now)
        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555"
        )

        ramp_elections = RampElection.established.where(veteran_file_number: veteran_file_number).all
        expect(ramp_elections.map(&:issues).flatten.count).to eq(1)
        expect(ramp_elections.map(&:issues).flatten.first.description).to eq("Left knee")
      end

      it "if there are multiple ramp elections with multiple issues" do
        Generators::Contention.build(
          claim_id: EndProductEstablishment.find_by(source: second_completed_ramp_election).reference_id,
          text: "Right elbow"
        )
        expect(subject).to be_truthy

        expect(intake.started_at).to eq(Time.zone.now)
        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555"
        )
        ramp_elections = RampElection.established.where(veteran_file_number: veteran_file_number).all
        expect(ramp_elections.count).to eq(2)
        expect(ramp_elections.map(&:issues).flatten.map(&:description).sort).to eq(["Right elbow", "Left knee"].sort)
      end
    end

    context "intake is already in progress" do
      it "should not create another intake" do
        RampRefilingIntake.new(
          user: user,
          veteran_file_number: veteran_file_number
        ).start!

        expect(intake).to_not be_nil
        expect(subject).to eq(false)
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    let!(:end_product) do
      Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: {
          claim_type_code: claim_type_code,
          end_product_type_code: modifier,
          claim_receive_date: claim_date,
          status_type_code: end_product_status,
          last_action_date: last_action_date
        }
      )
    end

    let(:claim_date) { nil }
    let(:modifier) { nil }
    let(:claim_type_code) { nil }
    let(:last_action_date) { nil }
    let(:end_product_status) { "CLR" }

    context "there is not a completed ramp election for veteran" do
      let!(:not_complete_ramp_election) do
        create(:ramp_election,
               veteran_file_number: veteran_file_number,
               notice_date: 3.days.ago)
      end

      it "adds did_not_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_complete_ramp_election")
      end
    end

    context "there is a completed ramp election for veteran" do
      let!(:ramp_election) do
        create(:ramp_election,
               veteran_file_number: veteran_file_number,
               notice_date: 3.days.ago,
               established_at: Time.zone.now,
               option_selected: "higher_level_review")
      end

      context "the EP associated with original RampElection is still pending" do
        let!(:end_product_establishment) do
          create(
            :end_product_establishment,
            veteran_file_number: veteran_file_number,
            source: ramp_election,
            established_at: Time.zone.now,
            synced_status: "PEND"
          )
        end

        it "adds ramp_election_is_active and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("ramp_election_is_active")
        end

        context "there is no End Product Establishment, but there is an active matching End Product" do
          let!(:end_product_establishment) { nil }
          let(:claim_date) { ramp_election.receipt_date.mdY }
          let(:modifier) { "682" }
          let(:claim_type_code) { "682HLRRRAMP" }
          let(:end_product_status) { "PEND" }

          it "adds ramp_election_is_active and returns false" do
            expect(subject).to eq(false)
            expect(intake.error_code).to eq("ramp_election_is_active")
          end
        end
      end

      context "the EP associated with original RampElection is closed" do
        let!(:end_product_establishment) do
          create(
            :end_product_establishment,
            :cleared,
            veteran_file_number: veteran_file_number,
            source: ramp_election,
            established_at: Time.zone.now
          )
        end

        context "there are no contentions on the EP" do
          it "adds ramp_election_no_issues and returns false" do
            expect(subject).to eq(false)
            expect(intake.error_code).to eq("ramp_election_no_issues")
          end
        end

        context "there are contentions on the EP" do
          let!(:ramp_election_contentions) do
            [Generators::Contention.build(claim_id: end_product.claim_id, text: "Left knee")]
          end

          let!(:end_product_establishment) do
            create(
              :end_product_establishment,
              source: ramp_election,
              reference_id: end_product.claim_id,
              veteran_file_number: veteran_file_number,
              synced_status: end_product_status
            )
          end

          before { ramp_election.recreate_issues_from_contentions! }

          it { is_expected.to eq(true) }

          context "there is no End Product Establishment, and the matching end products are closed" do
            let!(:end_product_establishment) { nil }
            let(:claim_date) { ramp_election.receipt_date.mdY }
            let(:modifier) { "682" }
            let(:claim_type_code) { "682HLRRRAMP" }
            let(:end_product_status) { "CLR" }
            let(:last_action_date) { (ramp_election.established_at + 1.day).to_date.mdY }

            it { is_expected.to eq(true) }
          end

          context "a saved RampRefiling already exists for the veteran" do
            let!(:preexisting_ramp_refiling) { RampRefiling.create!(veteran_file_number: veteran_file_number) }

            it "adds ramp_refiling_already_processed and returns false" do
              expect(subject).to eq(false)
              expect(intake.error_code).to eq("ramp_refiling_already_processed")
            end

            context "the preexisting RAMP refilings only have cancelled EPs" do
              let!(:other_refiling_epe) { create(:end_product_establishment, :canceled, source: preexisting_ramp_refiling) }

              it { is_expected.to eq(true) }
            end
          end
        end
      end
    end

    context "there are multiple completed ramp elections for veteran" do
      let!(:ramp_election1) do
        create(:ramp_election,
               veteran_file_number: veteran_file_number,
               notice_date: 3.days.ago,
               established_at: Time.zone.now)
      end
      let!(:ramp_election2) { second_completed_ramp_election }
      let!(:contention2) do
        Generators::Contention.build(
          claim_id: claim_id2,
          text: "Right elbow"
        )
      end

      let!(:end_product_establishment) do
        create(
          :end_product_establishment,
          source: ramp_election1,
          reference_id: end_product.claim_id,
          veteran_file_number: veteran_file_number,
          synced_status: end_product_status
        )
      end

      let(:claim_id1) { EndProductEstablishment.find_by(source: ramp_election1).reference_id }
      let(:claim_id2) { EndProductEstablishment.find_by(source: ramp_election2).reference_id }

      context "the EP associated with original RampElection is closed" do
        context "there are no contentions on the EP" do
          it "adds ramp_election_no_issues and returns false" do
            expect(subject).to eq(false)
            expect(intake.error_code).to eq("ramp_election_no_issues")
          end
        end

        context "there are contentions on the EP" do
          let!(:contentions) { ramp_election_contentions }
          before do
            ramp_election1.recreate_issues_from_contentions!
            ramp_election2.recreate_issues_from_contentions!
          end

          it { is_expected.to eq(true) }

          context "a saved RampRefiling already exists for the veteran" do
            let!(:preexisting_ramp_refiling) { RampRefiling.create!(veteran_file_number: "64205555") }

            it "adds ramp_election_no_issues and returns false" do
              expect(subject).to eq(false)
              expect(intake.error_code).to eq("ramp_refiling_already_processed")
            end
          end
        end
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:params) do
      {
        issue_ids: source_issues&.map(&:id),
        has_ineligible_issue: true
      }
    end

    let(:detail) do
      RampRefiling.create!(
        veteran_file_number: veteran_file_number,
        receipt_date: 10.seconds.ago,
        option_selected: option_selected,
        appeal_docket: appeal_docket
      )
    end

    let(:source_issues) do
      [
        completed_ramp_election.issues.create!(description: "Firsties"),
        completed_ramp_election.issues.create!(description: "Secondsies")
      ]
    end

    let(:appeal_docket) { nil }

    context "when end product is needed" do
      let(:option_selected) { "supplemental_claim" }

      it "saves issues and creates an end product" do
        expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

        subject

        expect(intake.reload).to be_success
        expect(intake.detail.issues.count).to eq(2)
        expect(intake.detail.has_ineligible_issue).to eq(true)
        expect(intake.detail.establishment_submitted_at).to eq(Time.zone.now)
        expect(intake.detail.establishment_processed_at).to eq(Time.zone.now)
      end

      context "when source_issues is nil" do
        let(:source_issues) { nil }

        it "works, but does not create an EP" do
          expect(Fakes::VBMSService).to_not receive(:establish_claim!)

          subject

          expect(intake.reload).to be_success
          expect(intake.detail.established_at).to eq(Time.zone.now)
          expect(intake.detail.issues.count).to eq(0)
          expect(intake.detail.has_ineligible_issue).to eq(true)
        end
      end
    end

    context "when no end product is needed" do
      let(:option_selected) { "appeal" }
      let(:appeal_docket) { Constants.AMA_DOCKETS.direct_review }

      it "saves issues and does NOT create an end product" do
        expect(Fakes::VBMSService).to_not receive(:establish_claim!)

        subject

        expect(intake.reload).to be_success
        expect(intake.detail.established_at).to eq(Time.zone.now)
        expect(intake.detail.issues.count).to eq(2)
        expect(intake.detail.has_ineligible_issue).to eq(true)
        expect(intake.detail.establishment_submitted_at).to eq(Time.zone.now)
        expect(intake.detail.establishment_processed_at).to eq(Time.zone.now)
      end
    end

    context "if end product creation fails" do
      let(:option_selected) { "supplemental_claim" }

      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end

      it "clears pending status" do
        allow_any_instance_of(RampRefiling).to receive(:create_end_product_and_contentions!).and_raise(unknown_error)

        expect { subject }.to raise_error(Caseflow::Error::EstablishClaimFailedInVBMS)
        expect(intake.completion_status).to be_nil
        expect(intake.detail.establishment_submitted_at).to eq(Time.zone.now)
        expect(intake.detail.establishment_processed_at).to be_nil
      end
    end

    context "if there are multiple ramp elections" do
      let!(:second_election) { second_completed_ramp_election }
      let!(:contention2) do
        Generators::Contention.build(
          claim_id: EndProductEstablishment.find_by(source: second_election).reference_id,
          text: "Right elbow"
        )
      end
      let(:option_selected) { "supplemental_claim" }

      it "saves issue and creates an end product" do
        expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

        subject

        expect(intake.reload).to be_success
        expect(intake.detail.issues.count).to eq(2)
        expect(intake.detail.has_ineligible_issue).to eq(true)
      end
    end
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) { RampRefiling.create!(veteran_file_number: veteran_file_number) }

    let!(:ramp_issue) do
      RampIssue.new(
        review_type: detail,
        contention_reference_id: "1234",
        description: "description",
        source_issue_id: "12345"
      )
    end

    it "cancels and deletes the refiling record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
      expect { ramp_issue.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when already complete" do
      let(:completed_at) { 2.seconds.ago }

      it "returns and does nothing" do
        expect(intake).to_not be_persisted
        expect(intake).to_not be_canceled
        expect(intake).to have_attributes(
          cancel_reason: nil,
          cancel_other: nil
        )
      end
    end

    context "when completion is pending" do
      let(:completion_status) { "pending" }

      it "returns and does nothing" do
        expect(intake).to_not be_persisted
        expect(intake).to_not be_canceled
        expect(intake).to have_attributes(
          cancel_reason: nil,
          cancel_other: nil
        )
      end
    end
  end

  context "#save_error!" do
    subject { intake.save_error!(code: "ineligible_for_higher_level_review") }

    let(:detail) { RampRefiling.create!(veteran_file_number: veteran_file_number) }

    it "saves as an error and deletes the refiling record created" do
      subject

      intake.reload
      expect(intake.error_code).to eq("ineligible_for_higher_level_review")
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
