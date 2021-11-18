# frozen_string_literal: true

describe BeaamAppealConcern do
  describe "#beaam?" do
    before { allow(Rails.env).to receive(:production?).and_return(true) }

    let(:appeal) { create(:appeal, id: 1) }
    subject { appeal.beaam? }
    context "non-BEAAM appeal" do
      it { is_expected.to eq false }
    end
    context "BEAAM appeal" do
      let(:appeal) { create(:appeal, id: BeaamAppealConcern::BEAAM_CASE_IDS.sample) }
      it { is_expected.to eq true }
    end
  end
end
