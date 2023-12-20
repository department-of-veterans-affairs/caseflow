# frozen_string_literal: true

describe EndProductUpdate do
  describe "#perform!" do
    let(:original_decision_review) { create(:higher_level_review, :processed, same_office: false) }
    let(:claim_date) { Time.zone.yesterday }
    let!(:veteran) { create(:veteran) }
    let!(:epe) do
      create(:end_product_establishment,
             code: old_code,
             source: original_decision_review,
             claim_date: claim_date,
             veteran_file_number: veteran.file_number)
    end
    let(:epu) do
      create(:end_product_update,
             original_decision_review: original_decision_review,
             end_product_establishment: epe,
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
        expect(epu.request_issues).to all have_attributes(nonrating_issue_category: "Unknown Issue Category")
      end
    end

    context "when the benefit type changes" do
      let(:old_code) { "030HLRR" }
      let(:new_code) { "030HLRRPMC" }
      let(:old_benefit_type) { "compensation" }
      let(:new_benefit_type) { "pension" }

      it "updates the decision review and request issues" do
        subject

        expect(epu.request_issues).to all have_attributes(benefit_type: "pension")
        expect(epu.original_decision_review.benefit_type).to eq "pension"
      end

      context "when the decision review has multiple end products" do
        let!(:other_epe) do
          create(:end_product_establishment, source: original_decision_review, code: "030HLRNR")
        end

        it "updates the benefit type on a new review stream and moves the EP and its issues" do
          allow(original_decision_review).to receive(:create_stream!).and_call_original

          expect(original_decision_review.end_product_establishments.count).to eq 2
          expect { subject }.to change { original_decision_review.end_product_establishments.count }.by(-1)
          expect(original_decision_review).to have_received(:create_stream!).once

          new_stream = epu.end_product_establishment.source

          expect(new_stream).to_not be original_decision_review
          expect(original_decision_review.benefit_type).to eq old_benefit_type
          expect(new_stream.benefit_type).to eq new_benefit_type
          expect(new_stream.same_office).to eq original_decision_review.same_office
          expect(epu.request_issues).to all have_attributes(benefit_type: new_benefit_type)
        end

        context "when the other stream already exists" do
          before { original_decision_review.find_or_create_stream!(new_benefit_type) }

          it "moves the EP and its issues to the existing stream" do
            allow(original_decision_review).to receive(:create_stream!).and_call_original
            existing_stream = HigherLevelReview.find_by(
              establishment_processed_at: original_decision_review.establishment_processed_at,
              benefit_type: new_benefit_type
            )

            expect(original_decision_review.end_product_establishments.count).to eq 2
            expect { subject }.to change { original_decision_review.end_product_establishments.count }.by(-1)
            expect(original_decision_review).to_not have_received(:create_stream!)
            expect(original_decision_review.benefit_type).to eq old_benefit_type
            expect(epu.end_product_establishment.source).to eq existing_stream
            expect(existing_stream.benefit_type).to eq new_benefit_type
            expect(epu.request_issues).to all have_attributes(benefit_type: new_benefit_type)
          end
        end
      end
    end

    context "when there is a matching EP in BGS" do
      let(:old_code) { "030HLRR" }
      let(:new_code) { "030HLRNR" }
      let(:claim_date) { 10.days.ago }

      it "updates the EP in BGS to have the new claim label" do
        subject
        ep = BGSService.new.get_end_products(epu.veteran_file_number).first
        expect(ep).to include(claim_type_code: new_code)
      end
    end
  end
end
