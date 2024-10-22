# frozen_string_literal: true

describe SavedSearchesController, :postgres, type: :controller do
  let(:user) { create(:user, :admin_intake_role, :with_saved_search_reports)}
  let(:saved_search) { create(:saved_search, user: user) }

  before do
    User.stub = user
  end

  describe "#create" do
    let(:valid_params) do
      {
        search: {
          name: Faker::Name.name,
          description: Faker::Lorem.sentence,
          saved_search: {
            report_type: "event_type_action",
            events: {
              "0": "added_issue_no_decision_date"
            },
            timing: {
              range: "last_7_days"
            },
            decision_review_type: {
              "0": "HigherLevelReview", "1": "SupplementalClaim"
            },
            business_line_slug: "vha"
          }
        }
      }
    end

    context "VHA user creating saved search" do
      it "should create search" do
        expect{
          post :create, params: valid_params
        }.to change(SavedSearch, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "#destory /saved_searches/:id" do
    context "VHA user saved search exists" do
      it "should delete search" do
        delete :destroy, params: { id: user.saved_searches.first.id }

        expect(response).to have_http_status(:ok)
      end
    end

    context "VHA user saved search not exists" do
      it "retunrs a not found error" do
        delete :destroy, params: { id: 0}

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
