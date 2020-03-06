# frozen_string_literal: true

describe RampElectionIntake, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let!(:current_user) { User.authenticate! }

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:compensation_issue) { create(:case_issue, :compensation) }
  let(:education_issue) { create(:case_issue, :education) }
  let(:issues) { [compensation_issue] }
  let(:completed_at) { nil }
  let(:case_status) { :status_advance }

  let(:intake) do
    RampElectionIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  let(:vacols_case) do
    create(
      :case,
      case_status,
      bfcorlid: "64205555C",
      case_issues: issues,
      bfdnod: 1.year.ago
    )
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "other", other: "Spelling canceled and cancellation is fun") }

    let(:detail) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 5.days.ago,
             option_selected: "supplemental_claim",
             receipt_date: 3.days.ago)
    end

    let!(:ramp_issue) do
      RampIssue.new(
        review_type: detail,
        contention_reference_id: "1234",
        description: "description",
        source_issue_id: "12345"
      )
    end

    it "cancels and clears detail values" do
      subject

      expect(intake.reload).to be_canceled
      expect(intake).to have_attributes(
        cancel_reason: "other",
        cancel_other: "Spelling canceled and cancellation is fun"
      )
      expect(detail.reload).to have_attributes(
        option_selected: nil,
        receipt_date: nil
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
        expect(detail.reload).to have_attributes(
          option_selected: "supplemental_claim",
          receipt_date: 3.days.ago.to_date
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
        expect(detail.reload).to have_attributes(
          option_selected: "supplemental_claim",
          receipt_date: 3.days.ago.to_date
        )
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!({}) }

    let(:detail) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 5.days.ago,
             option_selected: "supplemental_claim",
             receipt_date: 3.days.ago)
    end

    let!(:appeal_to_partially_close) do
      create(:legacy_appeal,
             vacols_case: create(
               :case,
               :status_advance,
               bfcorlid: "64205555C",
               bfdnod: 1.year.ago,
               case_issues: [compensation_issue, education_issue]
             ))
    end

    let!(:appeal_to_fully_close) do
      create(:legacy_appeal,
             vacols_case: create(
               :case,
               :status_advance,
               bfcorlid: "64205555C",
               bfdnod: 1.year.ago,
               case_issues: [create(:case_issue, :compensation)]
             ))
    end

    it "closes out the appeals correctly and creates an end product" do
      expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      subject

      resultant_end_product_establishment = EndProductEstablishment.find_by(source: intake.reload.detail)
      expect(intake).to be_success
      expect(intake.detail.established_at).to eq(Time.zone.now)
      expect(resultant_end_product_establishment).not_to be_nil
      expect(resultant_end_product_establishment.established_at).to eq(Time.zone.now)

      expect(appeal_to_fully_close.case_record.reload).to have_attributes(
        bfmpro: "HIS",
        bfddec: AppealRepository.dateshift_to_utc(Time.zone.now),
        bfdc: "P"
      )

      expect(appeal_to_fully_close.case_record.folder.timduser).to eq(user.regional_office)

      reloaded_issues = AppealRepository.issues(appeal_to_partially_close.vacols_id)
      education_issue = reloaded_issues.find { |i| i.program == :education }
      compensation_issue = reloaded_issues.find { |i| i.program == :compensation }

      expect(education_issue.disposition_id).to eq(nil)
      expect(compensation_issue.disposition_id).to eq("P")

      expect(appeal_to_partially_close.case_record.reload).to have_attributes(
        bfmpro: "ADV",
        bfddec: nil,
        bfdc: nil
      )

      expect(
        RampClosedAppeal.where(
          vacols_id: appeal_to_partially_close.vacols_id,
          ramp_election_id: detail.id,
          nod_date: appeal_to_partially_close.nod_date,
          closed_on: Time.zone.now,
          partial_closure_issue_sequence_ids: [compensation_issue.id]
        )
      ).to_not be_nil

      expect(
        RampClosedAppeal.where(
          vacols_id: appeal_to_fully_close.vacols_id,
          ramp_election_id: detail.id,
          nod_date: appeal_to_fully_close.nod_date,
          closed_on: Time.zone.now,
          partial_closure_issue_sequence_ids: nil
        )
      ).to_not be_nil
    end

    describe "if there is already an existing and matching EP" do
      let!(:matching_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: {
            claim_type_code: "683SCRRRAMP",
            claim_receive_date: detail.receipt_date.to_formatted_s(:short_date),
            end_product_type_code: "683"
          }
        )
      end

      it "should return 'connected' with an error" do
        subject

        expect(intake.reload).to be_success
        expect(intake.error_code).to eq("connected_preexisting_ep")
      end
    end

    describe "if there are existing ramp elections" do
      let(:existing_option_selected) { "supplemental_claim" }
      let(:status_type_code) { "PEND" }
      let(:preexisting_ep_receive_date) { 38.days.ago.to_formatted_s(:short_date) }

      let!(:preexisting_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: {
            claim_type_code: "683SCRRRAMP",
            claim_receive_date: preexisting_ep_receive_date,
            status_type_code: status_type_code,
            end_product_type_code: "683"
          }
        )
      end

      let!(:existing_ramp_election) do
        re = create(:ramp_election,
                    veteran_file_number: veteran_file_number,
                    notice_date: 40.days.ago,
                    option_selected: existing_option_selected,
                    receipt_date: 38.days.ago,
                    established_at: 38.days.ago)
        # must set the reference_id *after* we create it because otherwise the factory
        # will automatically create an EP that will overwrite preexisting_ep
        create(
          :end_product_establishment,
          veteran_file_number: veteran_file_number,
          source: re,
          synced_status: status_type_code,
          last_synced_at: 38.days.ago
        ).tap { |epe| epe.update!(reference_id: preexisting_ep.claim_id) }
        re
      end

      context "the existing RAMP election EP is active" do
        it "closes out legacy appeals and connects intake to the existing ramp election" do
          subject

          expect(appeal_to_fully_close.case_record.reload).to have_attributes(bfdc: "P")

          expect(
            RampClosedAppeal.where(
              vacols_id: appeal_to_partially_close.vacols_id,
              ramp_election_id: detail.id,
              nod_date: appeal_to_partially_close.nod_date,
              closed_on: Time.zone.now,
              partial_closure_issue_sequence_ids: [compensation_issue.id]
            )
          ).to_not be_nil

          expect(
            RampClosedAppeal.where(
              vacols_id: appeal_to_fully_close.vacols_id,
              ramp_election_id: detail.id,
              nod_date: appeal_to_fully_close.nod_date,
              closed_on: Time.zone.now,
              partial_closure_issue_sequence_ids: nil
            )
          ).to_not be_nil

          expect { detail.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      def veteran_end_products
        BGSService.new.get_end_products(veteran_file_number).map { |ep| EndProduct.from_bgs_hash(ep) }
      end

      context "the existing RAMP election EP is inactive" do
        let(:status_type_code) { "CAN" }

        it "establishes new ramp election" do
          expect(veteran_end_products.count).to eq 2

          subject

          expect(intake.reload).to be_success
          expect(intake.detail).to_not eq(existing_ramp_election)
          expect(intake.detail.established_at).to_not be_nil
          expect(veteran_end_products.count).to eq 3
          expect(veteran_end_products.map(&:claim_id)).to include(preexisting_ep.claim_id)
        end
      end

      context "a new Intake for an existing canceled RAMP election" do
        let(:status_type_code) { "CAN" }
        let(:preexisting_ep_receive_date) { detail.receipt_date.to_date.to_formatted_s(:short_date) }

        it "does not attempt to re-use the existing canceled EP" do
          expect(veteran_end_products.count).to eq 2
          expect(veteran_end_products.map(&:claim_id)).to include(preexisting_ep.claim_id)

          subject

          expect(intake.reload).to be_success
          expect(intake.detail).to_not eq(existing_ramp_election)
          expect(intake.detail.established_at).to_not be_nil
          expect(veteran_end_products.count).to eq 3
          expect(veteran_end_products.map(&:claim_id)).to include(preexisting_ep.claim_id)
          expect(intake.detail.end_product_establishment.reference_id).to_not eq(preexisting_ep.claim_id)
        end
      end

      context "existing RAMP election EP is a different type" do
        let(:existing_option_selected) { "higher_level_review" }

        it "establishes new ramp election" do
          subject

          expect(intake.reload).to be_success
          expect(intake.detail).to_not eq(existing_ramp_election)
          expect(intake.detail.established_at).to_not be_nil
        end
      end
    end

    context "if end product creation fails" do
      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end

      it "clears pending status" do
        allow_any_instance_of(RampReview).to receive(:create_or_connect_end_product!).and_raise(unknown_error)

        expect { subject }.to raise_error(Caseflow::Error::EstablishClaimFailedInVBMS)
        expect(intake.completion_status).to be_nil
      end
    end
  end

  context "#serialized_appeal_issues" do
    subject { intake.serialized_appeal_issues }

    let(:test_issue) do
      create(:case_issue,
             issprog: "02",
             isscode: "15",
             isslev1: "03",
             isslev2: "5257",
             issdesc: "Broken knee")
    end

    let!(:appeals) do
      [
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :status_advance,
            bfcorlid: "64205555C",
            case_issues: [
              create(:case_issue,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "03",
                     isslev2: "5252",
                     issdesc: "Broken thigh"),
              test_issue
            ]
          )
        ),
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :status_advance,
            bfcorlid: "64205555C",
            case_issues: [
              create(:case_issue,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "03",
                     isslev2: "5325",
                     issdesc: "")
            ]
          )
        )
      ]
    end

    it do
      is_expected.to eq([
                          {
                            id: appeals.first.id,
                            issues: [{
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5252 - Thigh, limitation of flexion of"
                              ],
                              note: "Broken thigh"
                            }, {
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5257 - Knee, other impairment of"
                              ],
                              note: "Broken knee"
                            }]
                          },
                          {
                            id: appeals.last.id,
                            issues: [{
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5325 - Muscle injury, facial muscles"
                              ],
                              note: nil
                            }]
                          }
                        ])
    end
  end

  context "#start!" do
    subject { intake.start! }
    let!(:ramp_appeal) { vacols_case }

    context "RAMP election with notice_date exists" do
      let!(:ramp_election) do
        create(:ramp_election, veteran_file_number: "64205555", notice_date: 5.days.ago)
      end

      it "creates a new RAMP Election and does not set detail to the existing RAMP Election" do
        expect(subject).to be_truthy

        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555",
          notice_date: nil
        )

        expect(intake.detail).to_not have_attributes(
          id: ramp_election.id
        )
      end
    end

    context "matching RAMP election does not exist" do
      it "creates a new RAMP election with no notice_date" do
        expect(subject).to be_truthy

        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555"
        )
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }
    let(:established_at) { nil }
    let!(:ramp_appeal) { vacols_case }
    let!(:ramp_election) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 6.days.ago,
             established_at: established_at)
    end
    let(:new_ramp_election) { RampElection.where(veteran_file_number: "64205555").last }

    context "the ramp election is complete" do
      let(:established_at) { Time.zone.now }

      it "returns true even if there is an existing ramp election" do
        expect(subject).to eq(true)
      end
    end

    context "there are no active appeals" do
      let(:case_status) { :status_complete }

      it "adds no_active_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_appeals")
      end
    end

    context "there are no active compensation appeals" do
      let(:issues) { [education_issue] }

      it "adds no_active_compensation_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_compensation_appeals")
      end
    end

    context "there are active but not eligible appeals" do
      let(:case_status) { :status_active }

      it "adds no_eligible_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_eligible_appeals")
      end
    end

    context "there are eligible appeals" do
      it { is_expected.to eq(true) }
    end
  end
end
