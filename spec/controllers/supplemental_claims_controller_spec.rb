# frozen_string_literal: true

describe SupplementalClaimsController, :postgres, type: :controller do
  describe "#udpate" do
    let(:supplemental_claim) { create(:supplemental_claim, :with_vha_issue)}

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
              { new: [], edited: [], cancelled: [] }
            }
          }
        )

        allow(NonAdmin::IssueModificationRequestsUpdater).to receive(:new).and_return(updater)
        allow(updater).to receive(:success?).and_return(true)

        expect(updater).to receive(:process!)

        post :update, params: {
          claim_id: supplemental_claim.uuid,
          issue_modification_requests: { new: [], edited: [], cancelled: [] },
          request_issues: [ { request_issue_id: supplemental_claim.request_issues.first.id } ]
        }

        expect(response.status).to eq 200
      end
    end

    context "When an admin user is requesting an issue modification" do
      let(:user) { create(:intake_admin_user, :vha_intake_admin) }
      let(:request_issues_data) {
        {
          request_issues: [
            { request_issue_id: supplemental_claim.request_issues.first.id }
          ]
        }
      }

      it "should call #request_issues_update.perform! and return 204" do
        request_issues_update = instance_double(RequestIssuesUpdate, {
            user: user,
            review: supplemental_claim
          }
        )

        allow(RequestIssuesUpdate).to receive(:new).and_return(request_issues_update)
        allow(request_issues_update).to receive(:request_issues_data=).and_return(request_issues_data)

        expect(request_issues_update).to receive(:perform!)

        post :update, params: {
          claim_id: supplemental_claim.uuid,
          request_issues: [ { request_issue_id: supplemental_claim.request_issues.first.id } ]
        }

        expect(response.status).to eq 204
      end
    end
  end
end
