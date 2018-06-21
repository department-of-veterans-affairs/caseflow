RSpec.describe TasksController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:judge_queue)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:judge_queue)
  end

  describe "GET tasks/xxx" do
    let(:user) { FactoryBot.create(:user) }
    before do
      User.stub = user
      FactoryBot.create(:staff, role, sdomainid: user.css_id)
    end

    context "user is an attorney" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 200
      end
    end

    context "user is a judge" do
      let(:role) { :judge_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 200
      end
    end

    context "user is neither judge nor attorney" do
      let(:role) { nil }

      it "should not process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 302
      end
    end
  end

  describe "POST /tasks" do
    let(:attorney) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }
    let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    before do
      User.stub = user
      @staff_user = FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    context "Co-located admin action" do
      before do
        FeatureToggle.enable!(:attorney_assignment)
      end

      after do
        FeatureToggle.disable!(:attorney_assignment)
      end

      context "when current user is a judge" do
        let(:role) { :judge_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "type": "CoLocatedAdminAction"
          }
        end

        it "should not be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 302
        end
      end

      context "when current user is an attorney" do
        let(:role) { :attorney_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "type": "CoLocatedAdminAction",
            "title": "address_verification",
            "instructions": "do this"
          }
        end

        it "should be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 201
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["status"]).to eq "assigned"
          expect(response_body["task"]["appeal_id"]).to eq appeal.id
          expect(response_body["task"]["instructions"]).to eq "do this"
          expect(response_body["task"]["title"]).to eq "address_verification"
        end

        context "when appeal is not found" do
          let(:params) do
            {
              "appeal_id": 4_646_464,
              "type": "CoLocatedAdminAction",
              "title": "address_verification"
            }
          end

          it "should not be successful" do
            post :create, params: { tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["detail"]).to eq "Appeal can't be blank"
          end
        end
      end
    end
  end
end
