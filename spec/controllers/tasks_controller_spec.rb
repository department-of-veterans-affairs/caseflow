RSpec.describe TasksController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:colocated_queue)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:colocated_queue)
  end

  describe "GET tasks/xxx" do
    let(:user) { create(:user) }
    before do
      User.stub = user
      create(:staff, role, sdomainid: user.css_id)
    end

    let!(:task1) { create(:colocated_task, assigned_by: user) }
    let!(:task2) { create(:colocated_task, assigned_by: user) }
    let!(:task3) { create(:colocated_task, assigned_by: user, status: "completed") }

    let!(:task4) do
      create(:colocated_task, assigned_to: user, appeal: create(:legacy_appeal, vacols_case: create(:case, :aod)))
    end
    let!(:task5) { create(:colocated_task, assigned_to: user, status: "in_progress") }
    let!(:task_ama_colocated_aod) do
      create(:ama_colocated_task, assigned_to: user, appeal: create(:appeal, advanced_on_docket: true))
    end
    let!(:task6) { create(:colocated_task, assigned_to: user, status: "completed") }
    let!(:task7) { create(:colocated_task) }

    let!(:task8) { create(:ama_judge_task, assigned_to: user) }
    let!(:task9) { create(:ama_judge_task, :in_progress, assigned_to: user) }
    let!(:task10) { create(:ama_judge_task, :completed, assigned_to: user) }

    context "when user is an attorney" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2
        expect(response_body.first["attributes"]["status"]).to eq "on_hold"
        expect(response_body.first["attributes"]["assigned_by"]["id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.first["attributes"]["veteran_name"]).to eq task1.appeal.veteran_full_name
        expect(response_body.first["attributes"]["veteran_file_number"]).to eq task1.appeal.veteran_file_number

        expect(response_body.second["attributes"]["status"]).to eq "on_hold"
        expect(response_body.second["attributes"]["assigned_by"]["id"]).to eq user.id
        expect(response_body.second["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.second["attributes"]["veteran_name"]).to eq task2.appeal.veteran_full_name
        expect(response_body.second["attributes"]["veteran_file_number"]).to eq task2.appeal.veteran_file_number
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
        expect(response_body.size).to eq 3
        assigned = response_body[0]
        expect(assigned["id"]).to eq task4.id.to_s
        expect(assigned["attributes"]["status"]).to eq "assigned"
        expect(assigned["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil
        expect(assigned["attributes"]["aod"]).to be true

        in_progress = response_body[1]
        expect(in_progress["id"]).to eq task5.id.to_s
        expect(in_progress["attributes"]["status"]).to eq "in_progress"
        expect(in_progress["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        ama = response_body[2]
        expect(ama["id"]).to eq task_ama_colocated_aod.id.to_s
        expect(ama["attributes"]["aod"]).to be true
      end
    end

    context "when getting tasks for a judge" do
      let(:role) { :judge_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "judge" }
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2
        expect(response_body.first["attributes"]["status"]).to eq "assigned"
        expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to be nil

        expect(response_body.second["attributes"]["status"]).to eq "in_progress"
        expect(response_body.second["attributes"]["assigned_to"]["id"]).to eq user.id
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
    let(:attorney) { create(:user) }
    let(:user) { create(:user) }
    let(:appeal) { create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }

    before do
      User.stub = user
      @staff_user = FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    context "Attornet task" do
      before do
        FeatureToggle.enable!(:judge_assignment_to_attorney)
      end

      after do
        FeatureToggle.disable!(:judge_assignment_to_attorney)
      end

      context "when current user is a judge" do
        let(:ama_appeal) { create(:appeal) }
        let(:ama_judge_task) { create(:ama_judge_task, assigned_to: user) }
        let(:role) { :judge_role }

        let(:params) do
          [{
            "external_id": ama_appeal.uuid,
            "type": "AttorneyTask",
            "assigned_to_id": attorney.id,
            "parent_id": ama_judge_task.id
          }]
        end

        it "should be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 201
          response_body = JSON.parse(response.body)["tasks"]["data"]
          expect(response_body.first["attributes"]["type"]).to eq "AttorneyTask"
          expect(response_body.first["attributes"]["appeal_id"]).to eq ama_appeal.id
          expect(response_body.first["attributes"]["docket_number"]).to eq ama_appeal.docket_number
          expect(response_body.first["attributes"]["appeal_type"]).to eq "Appeal"

          attorney_task = AttorneyTask.find_by(appeal: ama_appeal)
          expect(attorney_task.status).to eq "assigned"
          expect(attorney_task.assigned_to).to eq attorney
          expect(attorney_task.parent_id).to eq ama_judge_task.id
          expect(ama_judge_task.reload.status).to eq "on_hold"
        end
      end
    end

    context "Co-located admin action" do
      before do
        FeatureToggle.enable!(:attorney_assignment_to_colocated)
      end

      after do
        FeatureToggle.disable!(:attorney_assignment_to_colocated)
      end

      context "when current user is a judge" do
        let(:role) { :judge_role }
        let(:params) do
          [{
            "external_id": appeal.vacols_id,
            "type": "ColocatedTask"
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
              "external_id": appeal.vacols_id,
              "type": "ColocatedTask",
              "action": "address_verification",
              "instructions": "do this"
            },
             {
               "external_id": appeal.vacols_id,
               "type": "ColocatedTask",
               "action": "substitution_determination",
               "instructions": "another one"
             }]
          end

          it "should be successful" do
            expect(AppealRepository).to receive(:update_location!).exactly(1).times
            post :create, params: { tasks: params }
            expect(response.status).to eq 201
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq 2
            expect(response_body.first["attributes"]["status"]).to eq "assigned"
            expect(response_body.first["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.first["attributes"]["instructions"]).to eq "do this"
            expect(response_body.first["attributes"]["action"]).to eq "address_verification"

            expect(response_body.second["attributes"]["status"]).to eq "assigned"
            expect(response_body.second["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.second["attributes"]["instructions"]).to eq "another one"
            expect(response_body.second["attributes"]["action"]).to eq "substitution_determination"
            # assignee should be the same person
            id = response_body.second["attributes"]["assigned_to"]["id"]
            expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq id
          end
        end

        context "when one admin action" do
          let(:params) do
            {
              "external_id": appeal.vacols_id,
              "type": "ColocatedTask",
              "action": "address_verification",
              "instructions": "do this"
            }
          end

          it "should be successful" do
            post :create, params: { tasks: params }
            expect(response.status).to eq 201
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq 1
            expect(response_body.first["attributes"]["status"]).to eq "assigned"
            expect(response_body.first["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.first["attributes"]["instructions"]).to eq "do this"
            expect(response_body.first["attributes"]["action"]).to eq "address_verification"
          end
        end

        context "when appeal is not found" do
          let(:params) do
            [{
              "external_id": 4_646_464,
              "type": "ColocatedTask",
              "action": "address_verification"
            }]
          end

          it "should not be successful" do
            post :create, params: { tasks: params }
            expect(response.status).to eq 404
          end
        end
      end
    end
  end

  describe "PATCH /task/:id" do
    let(:colocated) { create(:user) }
    let(:attorney) { create(:user) }
    let(:judge) { create(:user) }

    before do
      create(:staff, :colocated_role, sdomainid: colocated.css_id)
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
      create(:staff, :judge_role, sdomainid: judge.css_id)
    end

    context "when updating status to in-progress and on-hold" do
      let(:admin_action) { create(:colocated_task, assigned_by: attorney, assigned_to: colocated) }

      it "should update successfully" do
        User.stub = colocated
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
      let(:admin_action) { create(:colocated_task, assigned_by: attorney, assigned_to: colocated) }

      it "should update successfully" do
        User.stub = colocated
        patch :update, params: { task: { status: "completed" }, id: admin_action.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["status"]).to eq "completed"
        expect(response_body.first["attributes"]["completed_at"]).to_not be nil
      end
    end

    context "when updating assignee" do
      let(:attorney_task) { create(:ama_attorney_task, assigned_by: judge, assigned_to: attorney) }
      let(:new_attorney) { create(:user) }

      it "should update successfully" do
        User.stub = judge
        create(:staff, :attorney_role, sdomainid: new_attorney.css_id)
        patch :update, params: { task: { assigned_to_id: new_attorney.id }, id: attorney_task.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq new_attorney.id
      end
    end

    context "when some other user updates another user's task" do
      let(:admin_action) { create(:colocated_task, assigned_by: attorney, assigned_to: create(:user)) }

      it "should return not be successful" do
        User.stub = colocated
        patch :update, params: { task: { status: "in_progress" }, id: admin_action.id }
        expect(response.status).to eq 302
      end
    end
  end
end
