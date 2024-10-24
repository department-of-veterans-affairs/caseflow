# frozen_string_literal: true

describe SavedSearchesController, :postgres, type: :controller do
  let(:user) { create(:user, :vha_admin_user, :with_saved_search_reports) }
  let(:saved_search) { create(:saved_search, user: user) }

  let(:default_user) { create(:user) }
  let(:vha_business_line) { VhaBusinessLine.singleton }
  let(:options) { { format: :json } }

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
        expect { post :create, params: valid_params }
          .to change(SavedSearch, :count).by(1)

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
        delete :destroy, params: { id: 0 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#index" do
    before do
      vha_business_line.add_user(default_user)
      User.stub = default_user
    end
    context "get saved search" do
      subject do
        get :index,
            params: options
      end

      context "user is not an vha admin" do
        it "returns unauthorized" do
          subject

          expect(response.status).to be 302
          expect(response.body).to match(/unauthorized/)
        end
      end

      context "user is vha admin" do
        before do
          OrganizationsUser.make_user_admin(default_user, vha_business_line)
        end

        let!(:user_searches) { create_list(:saved_search, 5, user: default_user) }
        let!(:other_user_searches) { create_list(:saved_search, 10) }

        it "returns a successful response" do
          subject

          expect(response.status).to eq 200
          expect(JSON.parse(response.body)["all_searches"].count).to eq(16)
          expect(JSON.parse(response.body)["user_searches"].count).to eq(5)
        end
      end
    end
  end

  describe "#show" do
    before do
      OrganizationsUser.make_user_admin(default_user, vha_business_line)
      User.stub = default_user
    end

    context "get single saved search" do
      let(:saved_search) do
        create(:saved_search,
               user: default_user,
               name: "Timing Specification Before",
               description: "Timing range before date")
      end

      subject do
        get :show,
            params: { id: saved_search.id, format: :json }
      end

      it "returns specific saved search" do
        subject

        expect(subject.response_code).to eq 200

        response = JSON.parse(subject.body)

        expect(response["attributes"]["name"]).to eq "Timing Specification Before"
        expect(response["attributes"]["description"]).to eq "Timing range before date"
      end
    end
  end
end
