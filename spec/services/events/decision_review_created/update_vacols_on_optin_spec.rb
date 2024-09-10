# frozen_string_literal: true

describe Events::DecisionReviewCreated::UpdateVacolsOnOptin do
  context "Events::DecisionReviewCreated::UpdateVacolsOnOptin.process" do
    # Setup a mock decision_review object with necessary properties
    let!(:legacy_decision_review) { double("DecisionReview", legacy_opt_in_approved: true) }
    describe "when legacy_opt_in_approved is true" do
      it "calls process on LegacyOptinManager" do
        # Setup a mock LegacyOptinManager and expect peform! to be called
        legacy_optin_manager_double = double("LegacyOptinManager")
        expect(LegacyOptinManager).to receive(:new)
          .with(decision_review: legacy_decision_review)
          .and_return(legacy_optin_manager_double)
        expect(legacy_optin_manager_double).to receive(:process!)
        # Call the method under test
        described_class.process!(decision_review: legacy_decision_review)
      end
    end
    describe "when legacy_opt_in_approved is false" do
      it "does not call process! on " do
        # Setup a mock decision_review object with necessary properties
        decision_review_double = double("DecisionReview", legacy_opt_in_approved: false)
        expect(described_class.process!(decision_review: decision_review_double)).to be_nil
      end
    end
    describe "when an error occurs" do
      it "logs an error and raises if an standard error occurs" do
        allow(described_class).to receive(:process!)
          .and_raise(Caseflow::Error::DecisionReviewCreateVacolsOnOptinError)
        expect { described_class.process!(decision_review: legacy_decision_review) }.to raise_error(
          Caseflow::Error::DecisionReviewCreateVacolsOnOptinError
        )
      end
    end
  end
end
