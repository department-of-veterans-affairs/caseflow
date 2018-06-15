describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:veteran) { Generators::Veteran.build(file_number: "12341234") }
  let(:code) { "030HLRR" }

  let(:end_product_establishment) do
    EndProductEstablishment.new(
      veteran: veteran,
      code: code,
      claim_date: 2.days.ago,
      station: "397",
      valid_modifiers: ["030"]
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
        expect(end_product_establishment.reference_id).to eq("FAKECLAIMID")
      end
    end
  end
end
