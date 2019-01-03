describe DecisionReviewsController, type: :controller do
  before do
    FeatureToggle.enable!(:decision_reviews)

    User.stub = user
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }

  describe "#index" do
    context "user is not in org" do
      it "returns unauthorized" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user is in org" do
      before do
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
      end

      it "displays org queue page" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 200
      end
    end

    context "business-line-slug is not found" do
      it "returns 404" do
        get :index, params: { business_line_slug: "foobar" }

        expect(response.status).to eq 404
      end
    end
  end

  describe "#show" do
    let(:task) { create(:higher_level_review_task).becomes(DecisionReviewTask) }

    context "user is in org" do
      before do
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
      end

      it "displays task details page" do
        get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

        expect(response.status).to eq 200
      end
    end

    context "user is not in org" do
      it "returns unauthorized" do
        get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end
  end
end
