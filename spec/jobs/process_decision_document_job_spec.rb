require "rails_helper"

describe ProcessDecisionDocumentJob, focus: true do
  context ".perform" do
    subject { ProcessDecisionDocumentJob.perform_now(decision_document) }

    let(:decision_document) { build(:decision_document) }

    it "processes the decision document" do
      expect(decision_document).to receive(:process!)
      subject
    end
  end
end
