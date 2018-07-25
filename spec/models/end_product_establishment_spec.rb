describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "12341234" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:code) { "030HLRR" }
  let(:reference_id) { nil }
  let(:source) { create(:ramp_election) }

  let(:end_product_establishment) do
    EndProductEstablishment.new(
      source: source,
      veteran_file_number: veteran_file_number,
      code: code,
      claim_date: 2.days.ago,
      station: "397",
      valid_modifiers: ["030"],
      reference_id: reference_id
    )
  end

  context "#perform!" do
    subject { end_product_establishment.perform! }

    before do
      Fakes::VBMSService.end_product_claim_ids_by_file_number ||= {}
      Fakes::VBMSService.end_product_claim_ids_by_file_number[veteran.file_number] = "FAKECLAIMID"
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

    context "when all goes well" do
      it "creates end product and sets reference_id" do
        subject
        expect(end_product_establishment.reload).to have_attributes(
          reference_id: "FAKECLAIMID",
          veteran_file_number: veteran_file_number,
          established_at: Time.zone.now
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
