# frozen_string_literal: true

describe SupplementalClaimsController, :postgres, type: :controller do
  describe "#update" do
    let(:supplemental_claim) { create(:supplemental_claim, :with_vha_issue) }

    before do
      User.stub = user
      supplemental_claim.establish!
    end

    context "When non admin user is requesting an issue modification " do
      let(:user) { create(:intake_user, :vha_default_user) }
      let(:issue_modification_request) do
        create(:issue_modification_request, decision_review: supplemental_claim)
      end

      it "should call #issues_modification_request_update.non_admin_process! and return 200" do
        updater = instance_double(
          IssueModificationRequests::Updater, {
            current_user: user,
            review: supplemental_claim,
            issue_modifications_data: {
              issue_modification_requests: {
                new: [], edited: [], cancelled: [
                  {
                    id: issue_modification_request.id, status: "assigned"
                  }
                ]
              }
            }
          }
        )

        allow(IssueModificationRequests::Updater).to receive(:new).and_return(updater)

        expect(updater).to receive(:non_admin_actions?).and_return(true)
        expect(updater).to receive(:non_admin_process!).and_return(true)

        post :update, params: {
          claim_id: supplemental_claim.uuid,
          request_issues: [{ request_issue_id: supplemental_claim.request_issues.first.id }],
          issue_modification_requests: {
            new: [],
            edited: [],
            cancelled: [
              {
                id: issue_modification_request.id, status: "assigned"
              }
            ]
          }
        }

        expect(response.status).to eq 200
      end
    end
  end
end
