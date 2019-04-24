# frozen_string_literal: true

require "rails_helper"

describe DocumentCountsByAppealId do
  describe "#call" do
    context "when there are more than 5 ids in the request" do
      it "throws an error" do
        expect do
          DocumentCountsByAppealId.new(
            appeal_ids: %w[123 123 123 123 123 123]
          ).call
        end.to raise_error(Caseflow::Error::TooManyAppealIds)
      end
    end

    context "when there are less than 5 ids in the request" do
      let!(:ama_appeal) { create(:appeal) }

      it "returns the appropriate hash via private methods" do
        allow_any_instance_of(DocumentFetcher).to receive(:number_of_documents)
          .and_return(10)
        result = DocumentCountsByAppealId.new(
          appeal_ids: [ama_appeal.external_id]
        ).call
        count_hash = result[ama_appeal.external_id]
        expect(count_hash).to_not eq(nil)
        expect(count_hash[:count]).to eq(10)
        expect(count_hash[:status]).to eq(200)
        expect(count_hash[:error]).to eq(nil)
      end
    end

    context "when there is an error fetching documents" do
      let!(:ama_appeal) { create(:appeal) }

      it "returns the appropriate hash via private methods" do
        error_msg = "Document count did not succeed"
        error = Caseflow::Error::DocumentRetrievalError.new(code: 502, message: error_msg)
        allow_any_instance_of(DocumentFetcher).to receive(:number_of_documents).and_raise(error)
        result = DocumentCountsByAppealId.new(
          appeal_ids: [ama_appeal.external_id]
        ).call
        response = { ama_appeal.external_id => { error: error_msg, status: 502 } }
        expect(result).to eq response
      end
    end

    context "when the appeal id does not exist" do
      it "returns a hash with error code" do
        result = DocumentCountsByAppealId.new(appeal_ids: %w[31r13r13r]).call
        response = { "31r13r13r" => { error: "ActiveRecord::RecordNotFound", status: 404 } }
        expect(result).to eq response
      end
    end
  end
end
