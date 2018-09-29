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
    let(:user) { create(:default_user) }
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
      create(:ama_colocated_task, assigned_to: user, appeal: create(:appeal, :advanced_on_docket))
    end
    let!(:task6) { create(:colocated_task, assigned_to: user, status: "completed") }
    let!(:task7) { create(:colocated_task) }

    let!(:task8) { create(:ama_judge_task, assigned_to: user, assigned_by: user) }
    let!(:task9) { create(:ama_judge_task, :in_progress, assigned_to: user, assigned_by: user) }
    let!(:task10) { create(:ama_judge_task, :completed, assigned_to: user, assigned_by: user) }

    let!(:task11) { create(:ama_attorney_task, assigned_to: user) }
    let!(:task12) { create(:ama_attorney_task, :in_progress, assigned_to: user) }
    let!(:task13) { create(:ama_attorney_task, :completed, assigned_to: user) }
    let!(:task14) { create(:ama_attorney_task, :on_hold, assigned_to: user) }

    context "when user is an attorney" do
      let(:role) { :attorney_role }

      it "should process the request successfully" do
        get :index, params: { user_id: user.id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 5
        expect(response_body.first["attributes"]["status"]).to eq "on_hold"
        expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.first["attributes"]["veteran_full_name"]).to eq task1.appeal.veteran_full_name
        expect(response_body.first["attributes"]["veteran_file_number"]).to eq task1.appeal.veteran_file_number

        expect(response_body.second["attributes"]["status"]).to eq "on_hold"
        expect(response_body.second["attributes"]["assigned_by"]["pg_id"]).to eq user.id
        expect(response_body.second["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.second["attributes"]["veteran_full_name"]).to eq task2.appeal.veteran_full_name
        expect(response_body.second["attributes"]["veteran_file_number"]).to eq task2.appeal.veteran_file_number

        ama_tasks = response_body.select { |task| task["type"] == "attorney_tasks" }
        expect(ama_tasks.size).to eq 3
        expect(ama_tasks.count { |task| task["attributes"]["status"] == "assigned" }).to eq 1
        expect(ama_tasks.count { |task| task["attributes"]["status"] == "in_progress" }).to eq 1
        expect(ama_tasks.count { |task| task["attributes"]["status"] == "on_hold" }).to eq 1
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

      it "should return 200" do
        get :index, params: { user_id: user.id, role: "unknown" }
        expect(response.status).to eq 200
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
               "action": "missing_records",
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
            expect(response_body.first["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.first["attributes"]["action"]).to eq "address_verification"

            expect(response_body.second["attributes"]["status"]).to eq "assigned"
            expect(response_body.second["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.second["attributes"]["instructions"][0]).to eq "another one"
            expect(response_body.second["attributes"]["action"]).to eq "missing_records"
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
            expect(response_body.first["attributes"]["instructions"][0]).to eq "do this"
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

  describe "PATCH /tasks/:id" do
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

  describe "GET appeals/:id/tasks" do
    let(:assigning_user) { create(:default_user) }
    let(:attorney_user) { create(:user) }
    let(:colocated_user) { create(:user) }

    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }
    let!(:colocated_staff) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }

    let!(:legacy_appeal) do
      create(:legacy_appeal, vacols_case: create(:case, :assigned, bfcorlid: "0000000000S", user: attorney_user))
    end
    let!(:appeal) do
      create(:appeal, veteran: create(:veteran))
    end

    let!(:colocated_task) { create(:colocated_task, appeal: legacy_appeal, assigned_by: assigning_user) }
    let!(:ama_colocated_task) do
      create(:ama_colocated_task, appeal: appeal, assigned_to: colocated_user, assigned_by: assigning_user)
    end

    context "when user is an attorney" do
      before { User.authenticate!(user: attorney_user) }
      it "should return AttorneyLegacyTasks" do
        get :for_appeal, params: { appeal_id: legacy_appeal.vacols_id, role: "attorney" }

        assert_response :success
        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 1
        task = response_body["tasks"][0]
        expect(task["id"]).to eq(legacy_appeal.vacols_id)
        expect(task["type"]).to eq("attorney_legacy_tasks")
        expect(task["attributes"]["user_id"]).to eq(attorney_user.css_id)
        expect(task["attributes"]["appeal_id"]).to eq(legacy_appeal.id)
      end
    end

    context "when user is a colocated staffer" do
      before { User.authenticate!(user: colocated_user) }

      it "should return ColocatedTasks" do
        get :for_appeal, params: { appeal_id: appeal.uuid, role: "colocated" }

        assert_response :success
        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 1

        task = response_body["tasks"][0]
        expect(task["type"]).to eq "colocated_tasks"
        expect(task["attributes"]["assigned_to"]["css_id"]).to eq colocated_user.css_id
        expect(task["attributes"]["appeal_id"]).to eq appeal.id
      end
    end

    context "when user is VSO" do
      let(:vso_user) { create(:user, roles: ["VSO"]) }
      let!(:vso_task) do
        create(:ama_colocated_task, appeal: appeal, assigned_to: vso_user, assigned_by: assigning_user)
      end
      before { User.authenticate!(user: vso_user) }

      it "should only return VSO tasks" do
        get :for_appeal, params: { appeal_id: appeal.uuid }

        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 1

        task = response_body["tasks"][0]
        expect(task["type"]).to eq "colocated_tasks"
        expect(task["attributes"]["assigned_to"]["css_id"]).to eq vso_user.css_id
        expect(task["attributes"]["appeal_id"]).to eq appeal.id

        expect(appeal.tasks.count).to eq 2
      end
    end
  end

  describe "GET tasks/:id/assignable_organizations" do
    context "when the task belongs to the user" do
      let(:user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:generic_task, assigned_to: user) }
      before { User.authenticate!(user: user) }

      context "when there are Organizations in the table" do
        let(:org_count) { 8 }
        before { FactoryBot.create_list(:organization, org_count) }

        it "should return a list of all Organizations" do
          get :assignable_organizations, params: { id: task.id }
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["organizations"].length).to eq(org_count)
        end
      end

      context "when there are Organizations and Organization subclasses in the table" do
        let(:org_count) { 5 }
        before do
          FactoryBot.create_list(:organization, org_count)
          FactoryBot.create_list(:vso, 2)
          FactoryBot.create_list(:bva, 1)
        end

        it "should return only a list of the Organizations" do
          get :assignable_organizations, params: { id: task.id }
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["organizations"].length).to eq(org_count)
        end
      end
    end

    context "when the task does not belong to the user" do
      let(:user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:generic_task) }
      before { User.authenticate!(user: user) }

      it "should redirect to unauthorized" do
        get :assignable_organizations, params: { id: task.id }
        expect(response.status).to eq(302)
        expect(response.location).to match(/\/unauthorized$/)
      end
    end
  end

  describe "GET tasks/:id/assignable_users" do
    context "when the task belongs to the user" do
      let(:root_task) { FactoryBot.create(:root_task) }

      let(:org_1) { FactoryBot.create(:organization) }
      let(:org_1_member_cnt) { 6 }
      let(:org_1_members) { FactoryBot.create_list(:user, org_1_member_cnt) }
      let(:org_1_assignee) { org_1_members[0] }
      let(:org_1_non_assignee) { org_1_members[1] }
      let(:org_1_team_task) { FactoryBot.create(:generic_task, assigned_to: org_1, parent: root_task) }
      let(:org_1_member_task) { FactoryBot.create(:generic_task, assigned_to: org_1_assignee, parent: org_1_team_task) }

      let(:org_2) { FactoryBot.create(:organization) }
      let(:org_2_member_cnt) { 17 }
      let(:org_2_members) { FactoryBot.create_list(:user, org_2_member_cnt) }
      let(:org_2_assignee) { org_2_members[0] }
      let(:org_2_non_assignee) { org_2_members[1] }
      let(:org_2_team_task) { FactoryBot.create(:generic_task, assigned_to: org_2, parent: org_1_member_task) }
      let!(:org_2_member_task) do
        FactoryBot.create(:generic_task, assigned_to: org_2_assignee, parent: org_2_team_task)
      end

      before do
        FeatureToggle.enable!(org_1.feature.to_sym, users: org_1_members.map(&:css_id))
        FeatureToggle.enable!(org_2.feature.to_sym, users: org_2_members.map(&:css_id))
      end

      after do
        FeatureToggle.disable!(org_1.feature.to_sym)
        FeatureToggle.disable!(org_2.feature.to_sym)
      end

      context "when user is assigned an individual task" do
        before { User.authenticate!(user: org_1_assignee) }

        it "should return a list of all members for individual task" do
          get :assignable_users, params: { id: org_1_member_task.id }
          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)
          expect(response_body["users"].length).to eq(org_1_member_cnt)
        end

        it "should return a list of all members for organization task" do
          get :assignable_users, params: { id: org_1_team_task.id }
          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)
          expect(response_body["users"].length).to eq(org_1_member_cnt)
        end

        it "should redirect to unauthorized for other organization child team task" do
          get :assignable_users, params: { id: org_2_team_task.id }
          expect(response.status).to eq(302)
          expect(response.location).to match(/\/unauthorized$/)
        end

        it "should redirect to unauthorized for other organization child member task" do
          get :assignable_users, params: { id: org_2_member_task.id }
          expect(response.status).to eq(302)
          expect(response.location).to match(/\/unauthorized$/)
        end
      end
    end

    context "when the task does not belong to the user" do
      let(:user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:generic_task) }
      before { User.authenticate!(user: user) }

      it "should redirect to unauthorized" do
        get :assignable_users, params: { id: task.id }
        expect(response.status).to eq(302)
        expect(response.location).to match(/\/unauthorized$/)
      end
    end
  end
end
