require "rails_helper"

describe EstablishClaim do
  let(:appeal) do
    Generators::Appeal.build(
      vacols_record: vacols_record,
      dispatched_to_station: dispatched_to_station,
      vamc: special_issues[:vamc],
      radiation: special_issues[:radiation]
    )
  end

  let(:establish_claim) do
    EstablishClaim.new(
      appeal: appeal,
      aasm_state: aasm_state,
      completion_status: Task.completion_status_code(completion_status),
      claim_establishment: claim_establishment
    )
  end

  let(:claim_establishment) do
    ClaimEstablishment.new(
      ep_code: ep_code,
      email_ro_id: email_ro_id,
      email_recipient: email_recipient
    )
  end

  let(:vacols_record) { :remand_decided }
  let(:dispatched_to_station) { "RO98" }
  let(:aasm_state) { :unassigned }
  let(:completion_status) { nil }
  let(:email_ro_id) { nil }
  let(:email_recipient) { nil }
  let(:special_issues) { {} }
  let(:ep_code) { nil }

  context "#perform!" do
    # Stub the id of the end product being created
    before do
      Fakes::AppealRepository.end_product_claim_id = "12345"
    end

    let(:claim_params) do
      {
        date: "03/03/2017",
        end_product_code: "172BVAG",
        end_product_label: "BVA Grant",
        end_product_modifier: claim_modifier,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        station_of_jurisdiction: "499"
      }
    end

    let(:dispatched_to_station) { nil }
    let(:aasm_state) { :started }
    let(:claim_modifier) { "170" }

    subject { establish_claim.perform!(claim_params) }

    context "when claim is valid" do
      it "sets status to reviewed and saves appropriate records" do
        subject

        expect(establish_claim.reload.reviewed?).to be_truthy
        expect(establish_claim.outgoing_reference_id).to eq("12345")
        expect(appeal.reload.dispatched_to_station).to eq("499")
        expect(claim_establishment.reload.ep_code).to eq("172BVAG")
      end
    end

    context "when claim is invalid" do
      let(:claim_modifier) { nil }

      it "raises InvalidClaimError and rolls back DB changes" do
        expect { subject }.to raise_error(EstablishClaim::InvalidClaimError)
      end
    end

    context "when VBMS throws an error" do
      before do
        allow(Appeal.repository).to receive(:establish_claim!).and_raise(vbms_error)

        # Save objects to test DB rollback stuff
        establish_claim.save!
        appeal.save!
      end

      let(:vbms_error) { VBMS::HTTPError.new("500", "some error") }

      it "rolls back DB changes" do
        expect { subject }.to raise_error(VBMS::HTTPError)

        expect(establish_claim.reload).to_not be_reviewed
        expect(establish_claim.outgoing_reference_id).to be_nil
        expect(appeal.reload.dispatched_to_station).to be_nil
        expect(claim_establishment.reload.ep_code).to be_nil
      end

      context "EP already exists error" do
        let(:vbms_error) do
          VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
            "A duplicate claim for this EP code already exists in CorpDB. Please " \
            "use a different EP code modifier. GUID: 13fcd</faultstring>")
        end

        it "raises EndProductAlreadyExistsError" do
          expect { subject }.to raise_error(EstablishClaim::EndProductAlreadyExistsError)
        end
      end

      context "EP already exists in BGS error" do
        let(:vbms_error) do
          VBMS::HTTPError.new("500", "<faultstring>Claim not established." \
            " BGS code; PIF is already in use.</faultstring>")
        end

        it "raises EndProductAlreadyExistsError" do
          expect { subject }.to raise_error(EstablishClaim::EndProductAlreadyExistsError)
        end
      end
    end
  end

  context "#actions_taken" do
    subject { establish_claim.actions_taken }

    context "when complete" do
      let(:aasm_state) { :completed }
      let(:completion_status) { :completed }

      context "when appeal is a Remand or Partial Grant" do
        let(:vacols_record) { :remand_decided }

        it { is_expected.to include("Reviewed Remand decision") }
        it { is_expected.to include("VACOLS Updated: Changed Location to 98") }

        context "when an EP was established for ARC" do
          let(:ep_code) { "170RMDAMC" }
          let(:dispatched_to_station) { "397" }

          it { is_expected.to include("Established EP: 170RMDAMC - ARC-Remand for Station 397 - ARC") }
          it { is_expected.to_not include(/Added Diary Note/) }
        end

        context "when the appeal was routed to an RO in VACOLS" do
          let(:special_issues) { { vamc: true } }

          it { is_expected.to include("VACOLS Updated: Changed Location to 54") }
          it { is_expected.to include("VACOLS Updated: Added Diary Note on VAMC") }
        end
      end

      context "when appeal is a Full Grant" do
        let(:vacols_record) { :full_grant_decided }

        it { is_expected.to include("Reviewed Full Grant decision") }
        it { is_expected.to_not include(/VACOLS Updated/) }

        context "when an EP was established" do
          let(:ep_code) { "172BVAG" }
          let(:dispatched_to_station) { "351" }

          it { is_expected.to include("Established EP: 172BVAG - BVA Grant for Station 351 - Muskogee") }

          context "when a VBMS Note was added to the EP" do
            let(:special_issues) { { vamc: true, radiation: true } }

            it { is_expected.to include("Added VBMS Note on Radiation; VAMC") }
          end
        end

        context "when processed via email" do
          let(:completion_status) { :special_issue_emailed }
          let(:email_ro_id) { "RO84" }
          let(:email_recipient) { "appealcoach@va.gov" }
          let(:special_issues) { { radiation: true } }

          it do
            is_expected
              .to include("Sent email to: appealcoach@va.gov in Philadelphia COWAC, PA - re: Radiation Issue(s)")
          end
        end

        context "when processed outside of caseflow" do
          let(:completion_status) { :special_issue_not_emailed }

          it { is_expected.to include("Processed case outside of Caseflow") }
        end
      end
    end

    context "when not complete" do
      let(:aasm_status) { :unassigned }

      it { is_expected.to eq([]) }
    end
  end
end
