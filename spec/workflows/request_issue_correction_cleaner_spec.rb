# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe "Request Issue Correction Cleaner", :postgres do
  before { allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original }

  let(:veteran) { create(:veteran) }

  let(:claim_review) do
    create(:higher_level_review,
      veteran_file_number: veteran.file_number,
      receipt_date: 2.weeks.ago,
      claimants: [build(:claimant, payee_code: "00")]
    )
  end

  let!(:remand_decision) { create(:decision_issue, decision_review: claim_review, disposition: "DTA Error") }

  let(:correction_request_issue) do
    create(:request_issue, correction_type: "control", contested_decision_issue: remand_decision_issue)
  end

  describe "#remove_dta_request_issue" do
    subject { RequestIssueCorrectionCleaner.new(correction_request_issue).remove_dta_request_issue! }

    context "when the dta claim only has issue being corrected" do
      it "closes the issue, removes the contention, and cancels the EP" do
        claim_review.create_remand_supplemental_claims!
        dta_issue_to_remove = remand_decision_issue.contesting_remand_request_issue

        subject

        expect(dta_issue_to_remove.closed_status).to eq("removed")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(dta_issue_to_remove.contention)
        expect(dta_issue_to_remove.end_product_establishment.synced_status).to eq("CAN")
      end
    end

    context "when the dta claim has other issues" do
      let!(:other_remand_decision) { create(:decision_issue, decision_review: claim_review, disposition: "DTA Error") }

      it "closes the issue, removes the contention, but does not cancels the EP" do
        claim_review.create_remand_supplemental_claims!
        dta_issue_to_remove = remand_decision_issue.contesting_remand_request_issue

        subject

        expect(dta_issue_to_remove.closed_status).to eq("removed")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(dta_issue_to_remove.contention)
        expect(dta_issue_to_remove.end_product_establishment.synced_status).to_not eq("CAN")
      end
    end
  end
end
