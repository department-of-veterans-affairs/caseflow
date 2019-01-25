require "rails_helper"

describe UpdateAttorneyCaseReview do
  describe "#call" do
    context "when the current user is not associated with the case" do
      it "does not update the case review" do
        review = create(:attorney_case_review)
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: valid_decision_document_id,
          user: build(:user, id: 123_456_789)
        ).call
        errors = { document_id: ["You are not authorized to edit this document ID"] }

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
          user: build(:user, id: review.reviewing_judge_id)
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
          user: build(:user, id: review.attorney_id)
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
          user: build(:user, id: review.attorney_id)
        ).call

        errors = {
          document_id: ["VHA Document IDs must be in one of these formats: V1234567.123 or V1234567.1234"]
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
          user: build(:user, id: review.attorney_id)
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
          user: build(:user, id: review.attorney_id)
        ).call

        errors = {
          document_id: ["IME Document IDs must be in one of these formats: M1234567.123 or M1234567.1234"]
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
          user: build(:user, id: review.attorney_id)
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
          user: build(:user, id: review.attorney_id)
        ).call

        error_message = "Draft Decision Document IDs must be in one of these formats: " \
                        "12345-12345678 or 12345678.123 or 12345678.1234"
        errors = {
          document_id: [error_message]
        }

        expect(result.errors).to eq errors
      end
    end

    context "when the AttorneyCaseReview cannot be found" do
      it "returns an error" do
        result = UpdateAttorneyCaseReview.new(
          id: 123,
          document_id: "V1234567.123",
          user: build(:user)
        ).call

        errors = {
          document_id: ["Could not find an Attorney Case Review with id 123"]
        }

        expect(result.errors).to eq errors
      end
    end

    def valid_decision_document_id
      "12345678.123"
    end
  end
end
