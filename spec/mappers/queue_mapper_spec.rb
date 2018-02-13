describe QueueMapper do
  context ".case_decision_fields_to_vacols_codes" do
    subject { QueueMapper.case_decision_fields_to_vacols_codes(info) }

    context "when all fields are present" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false,
          document_id: "123456789.1234",
          note: "Require action4" }
      end
      let(:expected_result) do
        { work_product: :IME,
          document_id: "123456789.1234",
          note: "Require action4" }
      end
      it { is_expected.to eq expected_result }
    end

    context "when not all fields are present" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: true,
          note: "Require action4" }
      end
      let(:expected_result) do
        { work_product: :OTI,
          note: "Require action4" }
      end
      it { is_expected.to eq expected_result }
    end
  end

  context ".work_product_to_vacols_format" do
    subject { QueueMapper.work_product_to_vacols_format(work_product, overtime) }
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
