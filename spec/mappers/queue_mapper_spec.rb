describe QueueMapper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".rename_and_validate_decass_attrs" do
    subject { QueueMapper.rename_and_validate_decass_attrs(info) }

    context "when all fields are present" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false,
          document_id: "123456789.1234",
          note: "Require action4" }
      end
      let(:expected_result) do
        { deprod: :IME,
          dedocid: "123456789.1234",
          deatcom: "Require action4",
          dereceive: VacolsHelper.local_date_with_utc_timezone }
      end
      it { is_expected.to eq expected_result }
    end

    context "when optional note is nil" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: true,
          note: nil,
          document_id: "123456789.1234" }
      end
      let(:expected_result) do
        { deprod: :OTI,
          deatcom: nil,
          dedocid: "123456789.1234",
          dereceive: VacolsHelper.local_date_with_utc_timezone }
      end
      it { is_expected.to eq expected_result }
    end

    context "when optional note is missing" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false,
          document_id: "123456789.1234" }
      end
      let(:expected_result) do
        { deprod: :IME,
          dedocid: "123456789.1234",
          dereceive: VacolsHelper.local_date_with_utc_timezone }
      end
      it { is_expected.to eq expected_result }
    end

    context "when required document ID is missing" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: true,
          note: "Require action4" }
      end
      it "raises an error" do
        expect { subject }.to raise_error(QueueRepository::QueueError)
      end
    end

    context "when required work product is missing" do
      let(:info) do
        { work_product: "Invalid",
          overtime: true,
          document_id: "1234",
          note: "Require action4" }
      end
      it "raises an error" do
        expect { subject }.to raise_error(QueueRepository::QueueError)
      end
    end
  end

  context ".work_product_to_vacols_code" do
    subject { QueueMapper.work_product_to_vacols_code(work_product, overtime) }
    context "when overtime" do
      let(:work_product) { "OMO - VHA" }
      let(:overtime) { true }
      it { is_expected.to eq :OTV }
    end

    context "when not overtime" do
      let(:work_product) { "OMO - VHA" }
      let(:overtime) { false }
      it { is_expected.to eq :VHA }
    end

    context "when unrecognized" do
      let(:work_product) { "unknown" }
      let(:overtime) { false }
      it { is_expected.to eq nil }
    end
  end
end
