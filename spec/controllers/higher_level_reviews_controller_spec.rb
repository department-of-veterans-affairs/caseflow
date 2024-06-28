# frozen_string_literal: true

describe HigherLevelReviewsController, :postgres, type: :controller do
  before do
    User.stub = user
  end

  let(:veteran) { create(:veteran) }
  let(:hlr) do
    create(:higher_level_review,
           :with_end_product_establishment,
           :processed,
           intake: create(:intake),
           veteran_file_number: veteran.file_number).reload
  end
  let(:user) { User.authenticate!(roles: ["Mail Intake"]) }

  describe "#edit" do
    before do
      hlr.establish!
    end

    it "finds by UUID" do
      get :edit, params: { claim_id: hlr.uuid }

      expect(response.status).to eq 200
    end

    it "finds by EPE reference_id" do
      get :edit, params: { claim_id: hlr.end_product_establishments.first.reference_id }

      expect(response.status).to eq 200
    end

    context "rating is locked" do
      before do
        allow(Rating).to receive(:fetch_in_range).and_raise(
          PromulgatedRating::LockedRatingError.new(message: "locked!")
        )
      end

      let!(:request_issue) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: "123",
          decision_review: hlr,
          end_product_establishment: hlr.end_product_establishments.first
        )
      end

      it "returns 422 error" do
        get :edit, params: { claim_id: hlr.uuid }

        expect(response.status).to eq 422
      end
    end
  end

  describe "#update" do
    let(:higher_level_review) { create(:higher_level_review, :with_vha_issue) }

    before do
      User.stub = user
      higher_level_review.establish!
    end

    context "When non admin user is requesting an issue modification " do
      let(:user) { create(:intake_user, :vha_default_user) }
      let(:issue_modification_request) do
        create(:issue_modification_request, decision_review: higher_level_review)
      end

      it "should call #issues_modification_request_update.non_admin_process! and return 200" do
        updater = instance_double(
          IssueModificationRequests::Updater, {
            current_user: user,
            review: higher_level_review,
            issue_modifications_data: {
              issue_modification_requests: {
                new: [],
                edited: [],
                cancelled: [
                  {
                    id: issue_modification_request.id,
                    status: "assigned"
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
          claim_id: higher_level_review.uuid,
          request_issues: [{ request_issue_id: higher_level_review.request_issues.first.id }],
          issue_modification_requests: {
            new: [],
            edited: [],
            cancelled: [
              {
                id: issue_modification_request.id,
                status: "assigned"
              }
            ]
          }
        }

        expect(response.status).to eq 200
      end
    end
  end
end
