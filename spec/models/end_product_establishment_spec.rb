describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "12341234" }
  let(:veteran_participant_id) { "11223344" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number, participant_id: veteran_participant_id) }
  let(:code) { "030HLRR" }
  let(:payee_code) { "00" }
  let(:reference_id) { nil }
  let(:source) { create(:ramp_election) }
  let(:invalid_modifiers) { nil }

  let(:end_product_establishment) do
    EndProductEstablishment.new(
      source: source,
      veteran_file_number: veteran_file_number,
      code: code,
      payee_code: payee_code,
      claim_date: 2.days.ago,
      station: "397",
      valid_modifiers: %w[030 031 032],
      reference_id: reference_id,
      invalid_modifiers: invalid_modifiers
      claimant_participant_id: veteran_participant_id
    )
  end

  context "#perform!" do
    subject { end_product_establishment.perform! }

    before do
      Fakes::VBMSService.end_product_claim_ids_by_file_number ||= {}
      Fakes::VBMSService.end_product_claim_ids_by_file_number[veteran.file_number] = "FAKECLAIMID"
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    end

    context "when end product is not valid" do
      let(:code) { nil }

      it "raises InvalidEndProductError" do
        expect { subject }.to raise_error(EndProductEstablishment::InvalidEndProductError)
      end
    end

    context "when VBMS throws an error" do
      let(:vbms_error) { VBMS::HTTPError.new("500", "PIF is already in use") }

      before do
        allow(VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
      end

      it "re-raises EstablishClaimFailedInVBMS error" do
        expect { subject }.to raise_error(Caseflow::Error::EstablishClaimFailedInVBMS)
      end
    end

    context "when an ep with a valid modifier already exists" do
      let!(:past_created_ep) do
        Generators::EndProduct.build(
          veteran_file_number: "12341234",
          bgs_attrs: { end_product_type_code: "030" }
        )
      end

      it "creates an end product with the next valid modifier" do
        subject
        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: 2.days.ago.to_date,
            end_product_modifier: "031",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: veteran.to_vbms_hash
        )
        expect(end_product_establishment.reload).to have_attributes(
          modifier: "031"
        )
      end

      context "when invalid modifiers is set" do
        let(:invalid_modifiers) { ["031"] }
        it "creates an ep with the next valid modifier" do
          subject
          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: "1",
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              station_of_jurisdiction: "397",
              date: 2.days.ago.to_date,
              end_product_modifier: "032",
              end_product_label: "Higher-Level Review Rating",
              end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
              gulf_war_registry: false,
              suppress_acknowledgement_letter: false
            },
            veteran_hash: veteran.to_vbms_hash
          )
          expect(end_product_establishment.reload).to have_attributes(
            modifier: "032"
          )
        end
      end
    end

    context "when all goes well" do
      it "creates end product and sets reference_id" do
        subject
        expect(end_product_establishment.reload).to have_attributes(
          reference_id: "FAKECLAIMID",
          veteran_file_number: veteran_file_number,
          established_at: Time.zone.now,
          modifier: "030"
        )
        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: 2.days.ago.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: veteran.to_vbms_hash
          claimant_participant_id: veteran_participant_id
        )
      end
    end
  end

  context "#result" do
    subject { end_product_establishment.result }

    let!(:other_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }
    let!(:matching_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }

    context "when matching end product has not yet been established" do
      context "when end_product.claim_id is nil" do
        it { is_expected.to be_nil }
      end

      context "when end_product_establishment.reference_id is set" do
        let(:reference_id) { "not matching" }

        it "raises EstablishedEndProductNotFound error" do
          expect { subject }.to raise_error(EndProductEstablishment::EstablishedEndProductNotFound)
        end
      end
    end

    context "when a matching end product has been established" do
      let(:reference_id) { matching_ep.claim_id }

      it { is_expected.to have_attributes(claim_id: matching_ep.claim_id) }
    end
  end

  context "#sync!" do
    subject { end_product_establishment.sync! }

    context "returns true if inactive" do
      before { end_product_establishment.update! synced_status: EndProduct::INACTIVE_STATUSES.first }

      it { is_expected.to eq(true) }
    end

    context "when matching end product has not yet been established" do
      it "raises EstablishedEndProductNotFound error" do
        expect { subject }.to raise_error(EndProductEstablishment::EstablishedEndProductNotFound)
      end
    end

    context "when a matching end product has been established" do
      let(:reference_id) { matching_ep.claim_id }
      let!(:matching_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: { status_type_code: "CAN" }
        )
      end

      it "updates last_synced_at and synced_status" do
        subject
        expect(end_product_establishment.reload.last_synced_at).to eq(Time.zone.now)
        expect(end_product_establishment.reload.synced_status).to eq("CAN")
      end
    end
  end

  context "#status_canceled?" do
    subject { end_product_establishment.status_canceled? }

    context "returns true if canceled" do
      before { end_product_establishment.synced_status = "CAN" }

      it { is_expected.to eq(true) }
    end

    context "returns false if any other status" do
      before { end_product_establishment.synced_status = "NOTCANCELED" }

      it { is_expected.to eq(false) }
    end
  end
end
