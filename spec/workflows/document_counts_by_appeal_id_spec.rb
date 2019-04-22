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
      it "return the appropriate hash via private methods" do
        expect do
            DocumentCountsByAppealId.new(
              appeal_ids: %w[123]
            ).call
          end .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
