require "rails_helper"

describe UpdateAttorneyCaseReview do
  describe "#call" do
    context "when the current user is not associated with the case" do
      it "does not update the case review" do
        review = create(:attorney_case_review)
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: valid_decision_document_id,
          user_id: 123_456_789
        ).call
        errors = { user_id: ["not authorized"] }

        expect(review.reload.document_id).to_not eq "123"
        expect(result.errors).to eq errors
      end
    end

    context "when the current user is a judge associated with the case" do
      it "updates the case review" do
        review = create(:attorney_case_review)
        UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: valid_decision_document_id,
          user_id: review.reviewing_judge_id
        ).call

        expect(review.reload.document_id).to eq valid_decision_document_id
      end
    end

    context "when the current user is an attorney associated with the case" do
      it "updates the case review" do
        review = create(:attorney_case_review)
        UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: valid_decision_document_id,
          user_id: review.attorney_id
        ).call

        expect(review.reload.document_id).to eq valid_decision_document_id
      end
    end

    context "when the work_product is 'OMO - VHA' but the document_id is in the wrong format" do
      it "returns an error" do
        review = create(:attorney_case_review, work_product: "OMO - VHA")
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.12",
          user_id: review.attorney_id
        ).call

        errors = {
          document_id: ["VHA document_ids must have the format V1234567.123 or V1234567.1234"]
        }

        expect(result.errors).to eq errors
      end
    end

    context "when the work_product is 'OMO - VHA' and the document_id is in the correct format" do
      it "updates successfully" do
        review = create(:attorney_case_review, work_product: "OMO - VHA")
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.123",
          user_id: review.attorney_id
        ).call

        expect(result.success?).to eq true
      end
    end

    context "when the work_product is 'OMO - IME' but the document_id is in the wrong format" do
      it "returns an error" do
        review = create(:attorney_case_review, work_product: "OMO - IME")
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.123",
          user_id: review.attorney_id
        ).call

        errors = {
          document_id: ["IME document_ids must have the format M1234567.123 or M1234567.1234"]
        }

        expect(result.errors).to eq errors
      end
    end

    context "when the work_product is 'OMO - IME' and the document_id is in the correct format" do
      it "updates successfully" do
        review = create(:attorney_case_review, work_product: "OMO - IME")
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "M1234567.1234",
          user_id: review.attorney_id
        ).call

        expect(result.success?).to eq true
      end
    end

    context "when the work_product is 'Decision' but the document_id is in the wrong format" do
      it "returns an error" do
        review = create(:attorney_case_review, work_product: "Decision")
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.123",
          user_id: review.attorney_id
        ).call

        errors = {
          document_id: ["Decision document_ids must have the format 12345-12345678 or 12345678.123 or 12345678.1234"]
        }

        expect(result.errors).to eq errors
      end
    end

    def valid_decision_document_id
      "12345678.123"
    end
  end
end
