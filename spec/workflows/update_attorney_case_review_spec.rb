# frozen_string_literal: true

describe UpdateAttorneyCaseReview, :postgres do
  describe "#call" do
    context "when the current user is not associated with the case" do
      it "does not update the case review" do
        review = create(:attorney_case_review)
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: valid_decision_document_id,
          user: build(:user, id: 123_456_789)
        ).call
        errors = {
          title: "Record is invalid",
          detail: "User not authorized to edit this document ID"
        }

        expect(review.reload.document_id).to_not eq "123"
        expect(result.errors).to eq [errors]
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
        review = create_vha_attorney_case_review
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.12",
          user: build(:user, id: review.attorney_id)
        ).call

        errors = {
          title: "Record is invalid",
          detail: "Document ID of type VHA must be in one of these formats: V1234567.123 or V1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'OMO - VHA' and the document_id is in the correct format" do
      it "updates successfully" do
        review = create_vha_attorney_case_review
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
        review = create_ime_attorney_case_review
        result = UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "V1234567.123",
          user: build(:user, id: review.attorney_id)
        ).call

        errors = {
          title: "Record is invalid",
          detail: "Document ID of type IME must be in one of these formats: M1234567.123 or M1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'OMO - IME' and the document_id is in the correct format" do
      it "updates successfully" do
        review = create_ime_attorney_case_review
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

        error_message = "Document ID of type Draft Decision must be in one of these formats: " \
                        "12345-12345678 or 12345678.123 or 12345678.1234"
        errors = {
          title: "Record is invalid",
          detail: error_message
        }

        expect(result.errors).to eq [errors]
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
          title: "Record is invalid",
          detail: "Attorney case review id 123 could not be found"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the document ID contains extra whitespace" do
      it "strips the whitespace" do
        review = create_vha_attorney_case_review
        UpdateAttorneyCaseReview.new(
          id: review.id,
          document_id: "  V1234567.123  ",
          user: build(:user, id: review.attorney_id)
        ).call

        expect(AttorneyCaseReview.last.document_id).to eq "V1234567.123"
      end
    end

    def create_vha_attorney_case_review
      create(
        :attorney_case_review,
        work_product: "OMO - VHA",
        document_id: "V1234567.1234"
      )
    end

    def create_ime_attorney_case_review
      create(
        :attorney_case_review,
        work_product: "OMO - IME",
        document_id: "M1234567.1234"
      )
    end

    def valid_decision_document_id
      "12345678.123"
    end
  end
end
