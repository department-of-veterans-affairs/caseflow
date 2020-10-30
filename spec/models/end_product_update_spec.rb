# frozen_string_literal: true

describe EndProductUpdate do
  describe "#perform!" do
    let(:epu) do
      create(:end_product_update,
             original_code: old_code,
             new_code: new_code)
    end
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

    context "when issue type changes" do
      let(:epu) do
        create(:end_product_update,
               original_code: "030HLRNR",
               new_code: "030HLRR")
      end

      it "updates issue type on request issues" do
        subject

        epe = epu.end_product_establishment
        expect(epe.request_issues).not_to be_empty
        expect(epe.request_issues).to all have_attributes(type: "RatingRequestIssue")
      end
    end
  end
end
