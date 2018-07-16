RSpec.describe TasksController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:judge_queue)
    FeatureToggle.enable!(:colocated_queue)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:judge_queue)
    FeatureToggle.disable!(:colocated_queue)
  end

  describe "GET tasks/xxx" do
    let(:user) { create(:user) }
    before do
      User.stub = user
      create(:staff, role, sdomainid: user.css_id)
      create(:colocated_admin_action, assigned_by: user)
      create(:colocated_admin_action, assigned_by: user)
      create(:colocated_admin_action, assigned_by: user, status: "completed")

      create(:colocated_admin_action, assigned_to: user)
      create(:colocated_admin_action, assigned_to: user, status: "in_progress")
      create(:colocated_admin_action, assigned_to: user, status: "completed")
      create(:colocated_admin_action)
    end

    context "when user is an attorney" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2
        expect(response_body.first["attributes"]["status"]).to eq "on_hold"
        expect(response_body.first["attributes"]["assigned_by_id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil

        expect(response_body.second["attributes"]["status"]).to eq "on_hold"
        expect(response_body.second["attributes"]["assigned_by_id"]).to eq user.id
        expect(response_body.second["attributes"]["placed_on_hold_at"]).to_not be nil
      end
    end

    context "when user is an attorney and has no tasks" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: create(:user).id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 0
      end
    end

    context "when user is a colocated admin" do
      let(:role) { :colocated_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "colocated" }
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2
        expect(response_body.first["attributes"]["status"]).to eq "assigned"
        expect(response_body.first["attributes"]["assigned_to_id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to be nil

        expect(response_body.second["attributes"]["status"]).to eq "in_progress"
        expect(response_body.second["attributes"]["assigned_to_id"]).to eq user.id
        expect(response_body.second["attributes"]["placed_on_hold_at"]).to be nil
      end
    end

    context "when user has no role" do
      let(:role) { nil }

      it "should return a 400 invalid role error" do
        get :index, params: { user_id: user.id, role: "unknown" }
        expect(response.status).to eq 400
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
          [{
            "appeal_id": appeal.id,
            "type": "CoLocatedAdminAction"
          }]
        end

        it "should not be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 302
        end
      end

      context "when current user is an attorney" do
        let(:role) { :attorney_role }

        context "when multiple admin actions" do
          let(:params) do
            [{
              "appeal_id": appeal.id,
              "type": "CoLocatedAdminAction",
              "title": "address_verification",
              "instructions": "do this"
            },
             {
               "appeal_id": appeal.id,
               "type": "CoLocatedAdminAction",
               "title": "substituation_determination",
               "instructions": "another one"
             }]
          end

          it "should be successful" do
            expect(AppealRepository).to receive(:update_location!).exactly(1).times
            post :create, params: { tasks: params }
            expect(response.status).to eq 201
            response_body = JSON.parse(response.body)
            expect(response_body["tasks"].size).to eq 2
            expect(response_body["tasks"].first["status"]).to eq "assigned"
            expect(response_body["tasks"].first["appeal_id"]).to eq appeal.id
            expect(response_body["tasks"].first["instructions"]).to eq "do this"
            expect(response_body["tasks"].first["title"]).to eq "address_verification"

            expect(response_body["tasks"].second["status"]).to eq "assigned"
            expect(response_body["tasks"].second["appeal_id"]).to eq appeal.id
            expect(response_body["tasks"].second["instructions"]).to eq "another one"
            expect(response_body["tasks"].second["title"]).to eq "substituation_determination"
            # assignee should be the same person
            expect(response_body["tasks"].first["assigned_to_id"]).to eq response_body["tasks"].second["assigned_to_id"]
          end
        end

        context "when one admin action" do
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
            expect(response_body["tasks"].size).to eq 1
            expect(response_body["tasks"].first["status"]).to eq "assigned"
            expect(response_body["tasks"].first["appeal_id"]).to eq appeal.id
            expect(response_body["tasks"].first["instructions"]).to eq "do this"
            expect(response_body["tasks"].first["title"]).to eq "address_verification"
          end
        end

        context "when appeal is not found" do
          let(:params) do
            [{
              "appeal_id": 4_646_464,
              "type": "CoLocatedAdminAction",
              "title": "address_verification"
            }]
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

  describe "PATCH /task/:id" do
    let(:user) { create(:user) }
    before do
      User.stub = user
      create(:staff, :colocated_role, sdomainid: user.css_id)
    end

    context "when updating status to in-progress and on-hold" do
      let(:admin_action) { create(:colocated_admin_action, assigned_to: user) }

      it "should update successfully" do
        patch :update, params: { task: { status: "in_progress" }, id: admin_action.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["status"]).to eq "in_progress"
        expect(response_body.first["attributes"]["started_at"]).to_not be nil

        patch :update, params: { task: { status: "on_hold", on_hold_duration: 60 }, id: admin_action.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["status"]).to eq "on_hold"
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil
      end
    end

    context "when updating status to completed" do
      let(:admin_action) { create(:colocated_admin_action, assigned_to: user) }

      it "should update successfully" do
        patch :update, params: { task: { status: "completed" }, id: admin_action.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["status"]).to eq "completed"
        expect(response_body.first["attributes"]["completed_at"]).to_not be nil
      end
    end

    context "when some other user updates another user's task" do
      let(:admin_action) { create(:colocated_admin_action, assigned_to: create(:user)) }

      it "should return not be successful" do
        patch :update, params: { task: { status: "in_progress" }, id: admin_action.id }
        expect(response.status).to eq 302
      end
    end
  end
end
