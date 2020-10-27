# frozen_string_literal: true

describe EndProductUpdate do
  describe "#perform!" do
    let(:epu) { create(:end_product_update, original_code: old_code, new_code: new_code) }
    subject { epu.perform! }

    context "when correction type changes" do
      let(:old_code) { "930AHCNRLPMC" }
      let(:new_code) { "930AHCNRNPMC" }
      it "updates correction type on request issues" do
        subject
        epe = epu.end_product_establishment
        expect(epe.code).to eq(new_code)
        expect(epe.request_issues).not_to be_empty
        expect(epe.request_issues).to all have_attributes(correction_type: "national_quality_error")
      end
    end
  end
end
