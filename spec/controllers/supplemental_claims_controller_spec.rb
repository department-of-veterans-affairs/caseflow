# frozen_string_literal: true

describe SupplementalClaimsController, :postgres, type: :controller do
  describe "#udpate" do
    let(:supplemental_claim) { create(:supplemental_claim, :with_vha_issue) }

    before do
      User.stub = user
      supplemental_claim.establish!
    end

    context "When non admin user is requesting an issue modification " do
      let(:user) { create(:intake_user, :vha_intake) }

      it "should call #issues_modification_request_update.process! and return 200" do
        updater = instance_double(
          NonAdmin::IssueModificationRequestsUpdater, {
            current_user: user,
            review: supplemental_claim,
            issue_modifications_data: { issue_modification_requests:
              {
                new: [], edited: [], cancelled: [
                  {
                    id: 1, status: "assigned"
                  }
                ]
              } }
          }
        )

        allow(NonAdmin::IssueModificationRequestsUpdater).to receive(:new).and_return(updater)
        allow(updater).to receive(:success?).and_return(true)

        expect(updater).to receive(:process!)

        post :update, params: {
          claim_id: supplemental_claim.uuid,
          request_issues: [{ request_issue_id: supplemental_claim.request_issues.first.id }],
          issue_modification_requests: {
            new: [],
            edited: [],
            cancelled: [
              {
                id: 1, status: "assigned"
              }
            ]
          }
        }

        expect(response.status).to eq 200
      end
    end
  end
end
