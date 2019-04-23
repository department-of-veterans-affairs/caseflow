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
        end .to raise_error(Caseflow::Error::TooManyAppealIds)
      end
    end
    context "when there are less than 5 ids in the request" do
      let(:veteran1) { create(:veteran) }

      let!(:ama_appeal) { create(:appeal, veteran: veteran1, number_of_claimants: 2) }

      it "returns the appropriate hash via private methods" do
        result = DocumentCountsByAppealId.new(
          appeal_ids: [ama_appeal.external_id]
        ).call
        count_hash = result[ama_appeal.external_id]
        expect(count_hash).to_not eq(nil)
        expect(count_hash[:count]).to eq(0)
        expect(count_hash[:status]).to eq(200)
        expect(count_hash[:error]).to eq(nil)
      end
    end
    context "when the appeal id does not exist" do
      let(:veteran1) { create(:veteran) }

      let!(:ama_appeal) { create(:appeal, veteran: veteran1, number_of_claimants: 2) }

      it "throws an ActiveRecord not found error" do
        expect do
          DocumentCountsByAppealId.new(
            appeal_ids: %w[31r13r13r]
          ).call
        end .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
