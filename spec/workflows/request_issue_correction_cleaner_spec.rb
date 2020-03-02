# frozen_string_literal: true

describe "Request Issue Correction Cleaner", :postgres do
  before { allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original }

  let(:veteran) { create(:veteran) }

  let(:claim_review) do
    create(:higher_level_review,
           veteran_file_number: veteran.file_number,
           receipt_date: 2.weeks.ago,
           claimants: [build(:claimant, payee_code: "00")])
  end

  let!(:remand_decision) { create(:decision_issue, decision_review: claim_review, disposition: "DTA Error") }
  let(:contested_decision_issue) { remand_decision }

  let(:correction_request_issue) do
    create(
      :request_issue,
      decision_review: claim_review,
      correction_type: "control",
      contested_decision_issue: contested_decision_issue
    )
  end

  describe "#remove_dta_request_issue" do
    subject { RequestIssueCorrectionCleaner.new(correction_request_issue).remove_dta_request_issue! }

    context "when the dta claim only has issue being corrected" do
      it "closes the issue, removes the contention, and cancels the EP" do
        claim_review.create_remand_supplemental_claims!
        dta_request_issue = remand_decision.contesting_remand_request_issue

        subject

        expect(dta_request_issue.closed_status).to eq("removed")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(dta_request_issue.contention)
        expect(dta_request_issue.end_product_establishment.synced_status).to eq("CAN")
      end

      context "when the issue being corrected is on a DTA claim" do
        let(:remand_supplemental_claim) { create(:supplemental_claim, decision_review_remanded: claim_review) }
        let(:granted_decision_issue) do
          create(:decision_issue, decision_review: remand_supplemental_claim, disposition: "granted")
        end
        let!(:correction_request_issue) do
          create(
            :request_issue,
            decision_review: remand_supplemental_claim,
            correction_type: "control",
            contested_decision_issue: granted_decision_issue
          )
        end

        it "does not try to remove itself" do
          dta_request_issue = granted_decision_issue.contesting_remand_request_issue
          expect(dta_request_issue).to eql(correction_request_issue)

          subject

          expect(correction_request_issue.reload.closed_status).to be nil
        end
      end
    end

    context "when the dta claim has other issues" do
      let!(:other_remand_decision) { create(:decision_issue, decision_review: claim_review, disposition: "DTA Error") }

      it "closes the issue, removes the contention, but does not cancels the EP" do
        claim_review.create_remand_supplemental_claims!
        dta_request_issue = remand_decision.contesting_remand_request_issue

        subject

        expect(dta_request_issue.closed_status).to eq("removed")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(dta_request_issue.contention)
        expect(dta_request_issue.end_product_establishment.synced_status).to_not eq("CAN")
      end
    end

    context "when the dta claim is already decided" do
      before do
        claim_review.create_remand_supplemental_claims!
        dta_request_issue = remand_decision.contesting_remand_request_issue
        create(:decision_issue, decision_review: dta_request_issue.decision_review, request_issues: [dta_request_issue])
        dta_request_issue.close_decided_issue!
        dta_request_issue.end_product_establishment.update!(synced_status: "CLR")
      end

      it "does not remove the issue, contentions or cancel the EP" do
        dta_request_issue = remand_decision.contesting_remand_request_issue

        subject
        expect(dta_request_issue.closed_status).to eq("decided")
        expect(Fakes::VBMSService).to_not have_received(:remove_contention!)
        expect(dta_request_issue.end_product_establishment.synced_status).to eq("CLR")
      end
    end
  end
end
