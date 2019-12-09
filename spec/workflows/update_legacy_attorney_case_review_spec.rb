# frozen_string_literal: true

describe UpdateLegacyAttorneyCaseReview, :all_dbs do
  describe "#call" do
    let(:judge) { build(:user, css_id: "JUDGE") }
    let(:attorney) { build(:user, css_id: "ATTORNEY") }
    let(:vacols_id) { "123456" }
    let(:document_id) { "V1234567.222" }
    let(:created_at) { "2019-02-14" }

    def stub_case_assignment_with_work_product(work_product)
      case_assignment = double(
        vacols_id: vacols_id,
        assigned_by_css_id: attorney.css_id,
        assigned_to_css_id: judge.css_id,
        document_id: document_id,
        work_product: work_product,
        created_at: created_at.to_date
      )
      allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(vacols_id).and_return(case_assignment)
    end

    def create_vha_attorney_case_review
      create(
        :attorney_case_review,
        work_product: "OMO - VHA",
        document_id: "V1234567.1234",
        task_id: "#{vacols_id}-#{created_at}"
      )
    end

    def create_ime_attorney_case_review
      create(
        :attorney_case_review,
        work_product: "OMO - IME",
        document_id: "M1234567.1234",
        task_id: "#{vacols_id}-#{created_at}"
      )
    end

    def create_decision_attorney_case_review
      create(
        :attorney_case_review,
        work_product: "Decision",
        document_id: "12345-12341234",
        task_id: "#{vacols_id}-#{created_at}"
      )
    end

    def valid_decision_document_id
      "12345678.123"
    end

    def valid_vha_document_id
      "V1234567.123"
    end

    def valid_ime_document_id
      "M1234567.123"
    end

    def invalid_document_id
      "1234567.123"
    end

    context "when the current user is not associated with the case" do
      it "does not update the case review" do
        stub_case_assignment_with_work_product("VHA")
        attorney_case_review = create_vha_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_vha_document_id,
          user: build(:user, id: 123_456_789)
        ).call
        errors = {
          title: "Record is invalid",
          detail: "You are not authorized to edit this document ID"
        }

        expect(attorney_case_review.reload.document_id).to_not eq valid_vha_document_id
        expect(result.errors).to eq [errors]
      end
    end

    context "when the current user is a judge associated with the case" do
      it "updates both the attorney case review and the VACOLS Decass table" do
        stub_case_assignment_with_work_product("VHA")
        attorney_case_review = create_vha_attorney_case_review

        decass = class_double(VACOLS::Decass)
        expect(VACOLS::Decass)
          .to receive(:where).with(defolder: vacols_id, deadtim: created_at.to_date).and_return(decass)
        expect(decass).to receive(:update_all).with(dedocid: valid_vha_document_id)

        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_vha_document_id,
          user: judge
        ).call

        expect(result.success?).to eq true
        expect(attorney_case_review.reload.document_id).to eq valid_vha_document_id
      end
    end

    context "when the current user is an attorney associated with the case" do
      it "updates the case review" do
        stub_case_assignment_with_work_product("VHA")
        attorney_case_review = create_vha_attorney_case_review
        UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_vha_document_id,
          user: attorney
        ).call

        expect(attorney_case_review.reload.document_id).to eq valid_vha_document_id
      end
    end

    context "when the work_product is 'VHA' but the document_id is in the wrong format" do
      it "returns an error" do
        stub_case_assignment_with_work_product("VHA")
        create_vha_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: invalid_document_id,
          user: attorney
        ).call

        errors = {
          title: "Record is invalid",
          detail: "VHA Document IDs must be in one of these formats: V1234567.123 or V1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'OTV' but the document_id is in the wrong format" do
      it "returns an error" do
        stub_case_assignment_with_work_product("OTV")
        create_vha_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: invalid_document_id,
          user: attorney
        ).call

        errors = {
          title: "Record is invalid",
          detail: "VHA Document IDs must be in one of these formats: V1234567.123 or V1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'IME' but the document_id is in the wrong format" do
      it "returns an error" do
        stub_case_assignment_with_work_product("IME")
        create_ime_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: invalid_document_id,
          user: attorney
        ).call

        errors = {
          title: "Record is invalid",
          detail: "IME Document IDs must be in one of these formats: M1234567.123 or M1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'OTI' but the document_id is in the wrong format" do
      it "returns an error" do
        stub_case_assignment_with_work_product("OTI")
        create_ime_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: invalid_document_id,
          user: attorney
        ).call

        errors = {
          title: "Record is invalid",
          detail: "IME Document IDs must be in one of these formats: M1234567.123 or M1234567.1234"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is a draft decision but the document_id is in the wrong format" do
      it "returns an error" do
        stub_case_assignment_with_work_product("DEC")
        create_decision_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: invalid_document_id,
          user: attorney
        ).call

        error_message = "Draft Decision Document IDs must be in one of these formats: " \
                        "12345-12345678 or 12345678.123 or 12345678.1234"
        errors = {
          title: "Record is invalid",
          detail: error_message
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the work_product is 'OTV' and the document_id is in the correct format" do
      it "updates successfully" do
        stub_case_assignment_with_work_product("OTV")
        attorney_case_review = create_vha_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_vha_document_id,
          user: judge
        ).call

        expect(result.success?).to eq true
        expect(attorney_case_review.reload.document_id).to eq valid_vha_document_id
      end
    end

    context "when the work_product is 'IME' and the document_id is in the correct format" do
      it "updates successfully" do
        stub_case_assignment_with_work_product("IME")
        attorney_case_review = create_ime_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_ime_document_id,
          user: attorney
        ).call

        expect(result.success?).to eq true
        expect(attorney_case_review.reload.document_id).to eq valid_ime_document_id
      end
    end

    context "when the work_product is 'OTI' and the document_id is in the correct format" do
      it "updates successfully" do
        stub_case_assignment_with_work_product("OTI")
        attorney_case_review = create_ime_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_ime_document_id,
          user: attorney
        ).call

        expect(result.success?).to eq true
        expect(attorney_case_review.reload.document_id).to eq valid_ime_document_id
      end
    end

    context "when the work_product is draft decision and the document_id is in the correct format" do
      it "updates successfully" do
        stub_case_assignment_with_work_product("DEC")
        attorney_case_review = create_decision_attorney_case_review
        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_decision_document_id,
          user: attorney
        ).call

        expect(result.success?).to eq true
        expect(attorney_case_review.reload.document_id).to eq valid_decision_document_id
      end
    end

    context "when the Vacols case assignment cannot be found" do
      it "returns an error" do
        attorney = build(:user, css_id: "ATTORNEY")
        vacols_id = "123"

        allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(vacols_id).and_return(nil)

        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: "V1234567.123",
          user: attorney
        ).call

        errors = {
          title: "Record is invalid",
          detail: "Could not find a legacy Attorney Case Review with id #{vacols_id}"
        }

        expect(result.errors).to eq [errors]
      end
    end

    context "when the attorney_case_review cannot be found" do
      it "does not attempt to update the AttorneyCaseReview table, but updates VACOLS" do
        case_assignment = double(
          vacols_id: vacols_id,
          assigned_by_css_id: attorney.css_id,
          assigned_to_css_id: judge.css_id,
          document_id: document_id,
          work_product: "DEC",
          created_at: created_at.to_date
        )
        allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(vacols_id).and_return(case_assignment)

        decass = class_double(VACOLS::Decass)
        expect(VACOLS::Decass)
          .to receive(:where).with(defolder: vacols_id, deadtim: created_at.to_date).and_return(decass)
        expect(decass).to receive(:update_all).with(dedocid: valid_decision_document_id)

        result = UpdateLegacyAttorneyCaseReview.new(
          id: vacols_id,
          document_id: valid_decision_document_id,
          user: judge
        ).call

        expect(result.success?).to eq true
      end
    end
  end
end
