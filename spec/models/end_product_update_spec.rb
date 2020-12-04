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

    context "when issue type changes from non-rating to rating" do
      let(:old_code) { "030HLRNR" }
      let(:new_code) { "030HLRR" }

      it "updates type and attributes on request issues" do
        subject

        expect(epu.request_issues).not_to be_empty
        expect(epu.request_issues).to all have_attributes(
          type: "RatingRequestIssue",
          description: "nonrating issue description"
        )
      end
    end

    context "when issue type changes from rating to non-rating" do
      let(:old_code) { "030HLRR" }
      let(:new_code) { "030HLRNR" }

      it "updates type and attributes on request issues" do
        subject

        expect(epu.request_issues).to all have_attributes(type: "NonratingRequestIssue")
        expect(epu.request_issues).to all have_attributes(nonrating_issue_category: "Unknown issue category")
      end
    end
  end
end
