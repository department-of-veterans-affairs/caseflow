# frozen_string_literal: true

RSpec.describe TasksController, :all_dbs, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vlj_support_staff) do
    Colocated.singleton.add_user(create(:user))
    Colocated.singleton.users.first
  end

  describe "GET tasks/xxx" do
    let(:user) { create(:default_user) }
    before do
      User.stub = user
      create(:staff, role, sdomainid: user.css_id)
    end

    context "when user is an attorney" do
      let(:role) { :attorney_role }

      let!(:task1) { create(:colocated_task, assigned_by: user) }
      let!(:task2) { create(:colocated_task, assigned_by: user) }
      let!(:task3) { create(:colocated_task, assigned_by: user) }

      let!(:task11) { create(:ama_attorney_task, assigned_to: user) }
      let!(:task12) { create(:ama_attorney_task, :in_progress, assigned_to: user) }
      let!(:task13) { create(:ama_attorney_task, :completed, assigned_to: user) }
      let!(:task16) { create(:ama_attorney_task, :completed_in_the_past, assigned_to: user) }
      let!(:task14) { create(:ama_attorney_task, assigned_to: user) }

      before do
        task3.update!(status: Constants.TASK_STATUSES.completed)
        task14.update!(status: Constants.TASK_STATUSES.on_hold)
      end

      it "should process the request successfully" do
        get :index, params: { user_id: user.id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]

        expect(response_body.size).to eq 6
        expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
        expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq user.id
        expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.first["attributes"]["veteran_full_name"]).to eq task1.appeal.veteran_full_name
        expect(response_body.first["attributes"]["veteran_file_number"]).to eq task1.appeal.veteran_file_number

        expect(response_body.second["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
        expect(response_body.second["attributes"]["assigned_by"]["pg_id"]).to eq user.id
        expect(response_body.second["attributes"]["placed_on_hold_at"]).to_not be nil
        expect(response_body.second["attributes"]["veteran_full_name"]).to eq task2.appeal.veteran_full_name
        expect(response_body.second["attributes"]["veteran_file_number"]).to eq task2.appeal.veteran_file_number

        # Ensure we include recently completed tasks
        expect(response_body.count { |task| task["id"] == task13.id.to_s }).to eq 1

        ama_tasks = response_body.select { |task| task["attributes"]["type"] == "AttorneyTask" }
        expect(ama_tasks.size).to eq 4
        expect(ama_tasks.count { |task| task["attributes"]["status"] == Constants.TASK_STATUSES.assigned }).to eq 1
        expect(ama_tasks.count { |task| task["attributes"]["status"] == Constants.TASK_STATUSES.in_progress }).to eq 1
        expect(ama_tasks.count { |task| task["attributes"]["status"] == Constants.TASK_STATUSES.on_hold }).to eq 1
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
      let!(:task4) do
        create(:colocated_task, assigned_to: user, appeal: create(:legacy_appeal, vacols_case: create(:case, :aod)))
      end
      let!(:task5) { create(:colocated_task, :in_progress, assigned_to: user) }
      let!(:task_ama_colocated_aod) do
        create(:ama_colocated_task, assigned_to: user, appeal: create(:appeal, :advanced_on_docket_due_to_age))
      end
      let!(:task6) { create(:colocated_task, :completed, assigned_to: user) }
      let!(:task7) { create(:colocated_task) }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "colocated" }
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 4

        assigned = response_body.find { |task| task["id"] == task4.id.to_s }
        expect(assigned["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
        expect(assigned["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil
        expect(assigned["attributes"]["aod"]).to be true

        in_progress = response_body.find { |task| task["id"] == task5.id.to_s }
        expect(in_progress["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
        expect(in_progress["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        ama = response_body.find { |task| task["id"] == task_ama_colocated_aod.id.to_s }
        expect(ama["attributes"]["aod"]).to be true

        recently_completed_task = response_body.find { |task| task["id"] == task6.id.to_s }
        expect(recently_completed_task["attributes"]["status"]).to eq Constants.TASK_STATUSES.completed
        expect(recently_completed_task["attributes"]["assigned_to"]["id"]).to eq user.id
      end
    end

    context "when getting tasks for a judge" do
      let(:role) { :judge_role }

      let!(:task8) { create(:ama_judge_task, assigned_to: user, assigned_by: user) }
      let!(:task9) { create(:ama_judge_task, :in_progress, assigned_to: user, assigned_by: user) }
      let!(:task10) { create(:ama_judge_task, :completed, assigned_to: user, assigned_by: user) }
      let!(:task15) do
        create(:ama_judge_task, :completed_in_the_past, assigned_to: user, assigned_by: user)
      end

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "judge" }
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 3

        assigned = response_body.find { |task| task["id"] == task8.id.to_s }
        expect(assigned["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
        expect(assigned["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil

        in_progress = response_body.find { |task| task["id"] == task9.id.to_s }
        expect(in_progress["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
        expect(in_progress["attributes"]["assigned_to"]["id"]).to eq user.id
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        # Ensure we include recently completed tasks
        expect(response_body.count { |task| task["id"] == task10.id.to_s }).to eq 1
      end
    end

    context "when user has no role" do
      let(:role) { nil }
      let(:veteran_file_number) { create(:veteran).file_number }

      it "should return 200" do
        get :index, params: { user_id: user.id, role: "unknown" }
        expect(response.status).to eq 200
      end

      it "should return queue config" do
        get :index, params: { user_id: user.id, role: "unknown" }
        expect(response.status).to eq 200
        queue_config = JSON.parse(response.body)["queue_config"]

        expect(queue_config.keys).to match_array(%w[table_title active_tab tasks_per_page use_task_pages_api tabs])
      end

      context "and theres a task to return" do
        let!(:vacols_case) do
          create(
            :case,
            folder: create(:folder, tinum: "docket-number"),
            bfregoff: "RO04",
            bfcurloc: "57",
            bfcorlid: "#{veteran_file_number}C",
            bfhr: "2",
            bfdocind: HearingDay::REQUEST_TYPES[:video]
          )
        end
        let!(:legacy_appeal) do
          create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: "RO04")
        end
        let!(:task) do
          create(:ama_task, assigned_to: user, appeal: legacy_appeal)
        end

        it "does not make a BGS call" do
          BGSService.instance_methods(false).each do |method_name|
            expect_any_instance_of(BGSService).not_to receive(method_name)
          end

          get :index, params: { user_id: user.id, role: "unknown" }
          expect(response).to have_http_status(:success)

          data = JSON.parse(response.body)["tasks"]["data"]

          expect(data.size).to be(1)
        end
      end

      context "when a task is assignable" do
        let(:root_task) { create(:root_task) }

        let(:org_1) { create(:organization) }
        let(:org_1_member_cnt) { 6 }
        let(:org_1_members) { create_list(:user, org_1_member_cnt) }
        let(:org_1_assignee) { org_1_members[0] }
        let(:org_1_non_assignee) { org_1_members[1] }
        let!(:org_1_team_task) { create(:ama_task, assigned_to: org_1, parent: root_task) }
        let!(:org_1_member_task) do
          create(:ama_task, assigned_to: org_1_assignee, parent: org_1_team_task)
        end

        before do
          org_1_members.each { |u| org_1.add_user(u) }
        end

        context "when user is assigned an individual task" do
          let!(:user) { User.authenticate!(user: org_1_assignee) }

          it "should return a list of all available actions for individual task" do
            get :index, params: { user_id: user.id }
            expect(response.status).to eq(200)
            response_body = JSON.parse(response.body)

            task_attributes = response_body["tasks"]["data"].find { |task| task["id"] == org_1_member_task.id.to_s }

            expect(task_attributes["attributes"]["available_actions"].length).to eq(5)

            # org count minus one since we can't assign to ourselves.
            assign_to_organization_action = task_attributes["attributes"]["available_actions"].find do |action|
              action["label"] == Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h[:label]
            end

            expect(assign_to_organization_action["data"]["options"].length).to eq(org_1_member_cnt - 1)
          end
        end
      end

      context "when the task belongs to the user" do
        let(:no_role_user) { create(:user) }
        let!(:task) { create(:ama_task, assigned_to: no_role_user) }
        before { User.authenticate!(user: no_role_user) }

        context "when there are Organizations in the table" do
          let(:org_count) { 8 }
          before { create_list(:organization, org_count) }

          it "should return a list of all Organizations" do
            get :index, params: { user_id: no_role_user.id }
            expect(response.status).to eq(200)
            response_body = JSON.parse(response.body)
            task_attributes = response_body["tasks"]["data"].find { |t| t["id"] == task.id.to_s }

            expect(task_attributes["attributes"]["available_actions"].length).to eq(5)

            assign_to_organization_action = task_attributes["attributes"]["available_actions"].find do |action|
              action["label"] == Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h[:label]
            end

            expect(assign_to_organization_action["data"]["options"].length).to eq(org_count + 1)
          end
        end
      end
    end
  end

  describe "POST /tasks" do
    let(:attorney) { create(:user) }
    let(:role) { nil }
    let(:user) { create(:user) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    before do
      User.stub = user
      @staff_user = create(:staff, role, sdomainid: user.css_id) if role
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    subject { post :create, params: { tasks: params } }

    context "Attorney task" do
      context "when current user is a judge" do
        let(:ama_appeal) { create(:appeal) }
        let(:ama_judge_task) { create(:ama_judge_task, assigned_to: user, appeal: ama_appeal) }
        let(:role) { :judge_role }

        let(:params) do
          [{
            "external_id": ama_appeal.uuid,
            "type": AttorneyTask.name,
            "assigned_to_id": attorney.id,
            "parent_id": ama_judge_task.id
          }]
        end

        it "should be successful" do
          subject

          expect(response.status).to eq 200

          response_body = JSON.parse(response.body)["tasks"]["data"]
          expect(response_body.second["attributes"]["type"]).to eq AttorneyTask.name
          expect(response_body.second["attributes"]["appeal_id"]).to eq ama_appeal.id
          expect(response_body.second["attributes"]["docket_number"]).to eq ama_appeal.docket_number
          expect(response_body.second["attributes"]["appeal_type"]).to eq Appeal.name

          attorney_task = AttorneyTask.find_by(appeal: ama_appeal)
          expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
          expect(attorney_task.assigned_to).to eq attorney
          expect(attorney_task.parent_id).to eq ama_judge_task.id
          expect(ama_judge_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        end
      end
    end

    context "VSO user" do
      let(:user) { create(:default_user, roles: ["VSO"]) }
      let(:vso) { create(:vso) }
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:role) { nil }

      before do
        User.authenticate!(user: user)
        vso.add_user(user)
        allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
      end

      context "when creating a task" do
        let(:params) do
          [{
            "external_id": appeal.external_id,
            "type": Task.name,
            "assigned_to_id": user.id,
            "parent_id": root_task.id
          }]
        end

        it "should not be successful" do
          subject

          expect(response.status).to eq 403
        end
      end

      context "when creating a mix of tasks" do
        let(:ihp_org_task) do
          create(
            :informal_hearing_presentation_task,
            appeal: appeal,
            assigned_to: vso
          )
        end

        let(:params) do
          [{
            "external_id": appeal.external_id,
            "type": InformalHearingPresentationTask.name,
            "assigned_to_id": user.id,
            "parent_id": ihp_org_task.id
          }, {
            "external_id": appeal.external_id,
            "type": Task.name,
            "assigned_to_id": user.id,
            "parent_id": root_task.id
          }]
        end

        it "should not be successful" do
          subject

          expect(response.status).to eq 403
          response_body = JSON.parse(response.body)["errors"].first["detail"]
          expect(response_body).to eq "VSOs cannot create that task."
        end
      end

      context "when creating a ihp task" do
        let(:ihp_org_task) do
          create(
            :informal_hearing_presentation_task,
            appeal: appeal,
            assigned_to: vso
          )
        end

        let(:params) do
          [{
            "external_id": appeal.external_id,
            "type": InformalHearingPresentationTask.name,
            "assigned_to_id": user.id,
            "parent_id": ihp_org_task.id
          }]
        end

        it "should be successful" do
          subject

          expect(response.status).to eq 200
        end
      end
    end

    context "Co-located admin action" do
      before do
        u = create(:user)
        Colocated.singleton.add_user(u)
      end

      context "when current user is an attorney" do
        let(:role) { :attorney_role }

        context "when multiple admin actions with task type field" do
          let(:params) do
            [{
              "external_id": appeal.vacols_id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": "do this"
            },
             {
               "external_id": appeal.vacols_id,
               "type": MissingRecordsColocatedTask.name,
               "instructions": "another one"
             }]
          end

          before do
            u = create(:user)
            Colocated.singleton.add_user(u)
          end

          it "should be successful" do
            expect(AppealRepository).to receive(:update_location!).exactly(2).times

            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq(4)
            expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
            expect(response_body.first["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.first["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.first["attributes"]["label"]).to eq "Address verification"

            expect(response_body.second["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.second["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.second["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.second["attributes"]["label"]).to eq "Address verification"
            # assignee should be the same person
            id = response_body.second["attributes"]["assigned_to"]["id"]
            expect(response_body.last["attributes"]["assigned_to"]["id"]).to eq id

            expect(response_body.last["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.last["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.last["attributes"]["instructions"][0]).to eq "another one"
            expect(response_body.last["attributes"]["label"]).to eq "Missing records"
          end
        end

        context "when one admin action with task type field" do
          let(:params) do
            {
              "external_id": appeal.vacols_id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": "do this"
            }
          end

          it "should be successful" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq(2)
            expect(response_body.last["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.last["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.last["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.last["attributes"]["label"]).to eq "Address verification"
          end
        end

        context "when one admin action with task label field" do
          let(:params) do
            {
              "external_id": appeal.vacols_id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": "do this"
            }
          end

          it "should be successful" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq(2)
            expect(response_body.last["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.last["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.last["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.last["attributes"]["label"]).to eq "Address verification"
          end
        end

        context "when appeal is not found" do
          let(:params) do
            [{
              "external_id": 4_646_464,
              "type": AddressVerificationColocatedTask.name
            }]
          end

          it "should not be successful" do
            subject

            expect(response.status).to eq 404
          end
        end
      end
    end

    context "hearing user and hearing admin action tasks" do
      let(:role) { :hearing_coordinator }
      let!(:user) { create(:user, roles: ["Build HearSched"]) }
      let!(:appeal) { create(:appeal) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }
      let(:incarcerated_instructions) { "Incarcerated veteran task instructions" }
      let(:contested_instructions_1) { "Contested claimant task instructions" }
      let(:contested_instructions_2) { "Instructions for another contested claimant task" }
      let(:params) do
        [
          {
            "instructions": incarcerated_instructions,
            "type": HearingAdminActionIncarceratedVeteranTask.name,
            "external_id": appeal.external_id,
            "parent_id": schedule_hearing_task.id.to_s
          },
          {
            "instructions": contested_instructions_1,
            "type": HearingAdminActionContestedClaimantTask.name,
            "external_id": appeal.external_id,
            "parent_id": schedule_hearing_task.id.to_s
          },
          {
            "instructions": contested_instructions_2,
            "type": HearingAdminActionContestedClaimantTask.name,
            "external_id": appeal.external_id,
            "parent_id": schedule_hearing_task.id.to_s
          }
        ]
      end

      before do
        HearingsManagement.singleton.add_user(user)
      end

      it "creates tasks with the correct types" do
        expect(HearingAdminActionTask.count).to eq 0

        subject

        expect(HearingAdminActionTask.count).to eq 3
        expect(HearingAdminActionTask.all.map(&:parent).uniq).to match_array([schedule_hearing_task])
        expect(HearingAdminActionTask.all.map(&:appeal).uniq).to match_array([appeal])

        expect(HearingAdminActionIncarceratedVeteranTask.count).to eq 1
        expect(HearingAdminActionIncarceratedVeteranTask.first.instructions).to include incarcerated_instructions

        expect(HearingAdminActionContestedClaimantTask.count).to eq 2
        expect(
          HearingAdminActionContestedClaimantTask.all.map(&:instructions).flatten
        ).to match_array([contested_instructions_1, contested_instructions_2])
      end
    end

    context "When the current user is a member of the Mail team" do
      before do
        mail_team_user = create(:user)
        MailTeam.singleton.add_user(mail_team_user)
        User.authenticate!(user: mail_team_user)
      end

      context "when an EvidenceOrArgumentMailTask is created for an inactive appeal" do
        let(:root_task) { create(:root_task) }

        let(:params) do
          [{
            "external_id": root_task.appeal.external_id,
            "type": EvidenceOrArgumentMailTask.name,
            "parent_id": root_task.id
          }]
        end

        before do
          allow(EvidenceOrArgumentMailTask).to receive(:case_active?).and_return(false)
        end

        it "returns a response indicating failure to create task" do
          subject

          response_body = JSON.parse(response.body)

          expect(response_body["errors"].first["status"]).to eq(500)
          expect(response_body["errors"].first["detail"]).to eq(Caseflow::Error::MailRoutingError.new.message)
        end
      end
    end
  end

  describe "PATCH /tasks/:id" do
    let(:authenticated_user) { create(:user, station_id: "101") }
    let(:assigned_by_user) { create(:user, station_id: "101") }
    let(:assigned_to_user) { authenticated_user }
    let(:task_type) { :colocated_task }
    let(:admin_action) { create(task_type, assigned_by: assigned_by_user, assigned_to: assigned_to_user) }
    let!(:authenticated_staff) { create(:staff, :colocated_role, sdomainid: authenticated_user.css_id) }
    let!(:assigned_by_staff) { create(:staff, :attorney_role, sdomainid: assigned_by_user.css_id) }
    let(:root_task) { create(:root_task) }
    let(:colocated_task) { create(:colocated_task, parent: root_task) }
    before do
      User.stub = authenticated_user
    end

    it "updates status to in_progress" do
      patch :update, params: { task: { status: Constants.TASK_STATUSES.in_progress }, id: admin_action.id }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["tasks"]["data"]
      expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
      expect(response_body.first["attributes"]["started_at"]).to_not be nil
    end

    it "updates status to on_hold" do
      patch :update, params: { task: { status: Constants.TASK_STATUSES.on_hold }, id: admin_action.id }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["tasks"]["data"]
      expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
      expect(response_body.first["attributes"]["placed_on_hold_at"]).to_not be nil
    end

    it "updates status to completed" do
      expect(admin_action.versions.length).to be 0
      expect(admin_action.parent.versions.length).to be 1
      patch :update, params: { task: { status: Constants.TASK_STATUSES.completed }, id: admin_action.id }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["tasks"]["data"]
      expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.completed
      expect(response_body.first["attributes"]["closed_at"]).to_not be nil
      expect(admin_action.reload.versions.length).to eq 1
      expect(admin_action.parent.versions.length).to eq 2
      versions = PaperTrail::Version.where(request_id: admin_action.versions.first.request_id)
      expect(versions.length).to eq 3
    end

    context "when some other user updates another user's task" do
      let(:assigned_by_user) { create(:user) }
      let!(:assigned_by_user_staff) { create(:staff, :attorney_role, sdomainid: assigned_by_user.css_id) }
      let(:assigned_to_user) { create(:user) }

      it "should return an error" do
        patch :update, params: { task: { status: Constants.TASK_STATUSES.in_progress }, id: admin_action.id }
        expect(response.status).to eq 403
      end
    end

    context "when updating assignee" do
      let!(:authenticated_staff) { create(:staff, :attorney_role, sdomainid: authenticated_user.css_id) }
      let!(:assigned_by_staff) { create(:staff, :judge_role, sdomainid: assigned_by_user.css_id) }
      let(:task_type) { :ama_attorney_task }
      let(:new_assigned_to_user) { create(:user) }
      let!(:new_assigned_to_staff) { create(:staff, :attorney_role, sdomainid: new_assigned_to_user.css_id) }

      it "should update successfully" do
        patch :update, params: { task: { assigned_to_id: new_assigned_to_user.id }, id: admin_action.id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["id"]).to eq admin_action.id.to_s
      end
    end
  end

  describe "GET appeals/:id/tasks" do
    let(:assigning_user) { create(:default_user) }
    let(:attorney_user) { create(:user) }
    let(:judge_user) { create(:user) }
    let(:colocated_user) { create(:user) }

    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }
    let!(:colocated_staff) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }

    let!(:legacy_appeal) do
      create(:legacy_appeal,
             vacols_case: create(:case, :assigned, bfcorlid: "0000000000S", user: attorney_user))
    end
    let!(:appeal) do
      create(:appeal, veteran: create(:veteran))
    end

    let!(:colocated_task) { create(:colocated_task, :ihp, appeal: legacy_appeal, assigned_by: assigning_user) }
    let!(:ama_colocated_task) do
      create(:ama_colocated_task, :ihp, appeal: appeal, assigned_to: colocated_user, assigned_by: assigning_user)
    end

    context "when user is a judge" do
      let(:legacy_appeal) do
        create(:legacy_appeal,
               vacols_case:
               create(:case, :assigned, bfcorlid: "0000000000S", user: judge_user))
      end

      before do
        DatabaseRequestCounter.enable
        User.authenticate!(user: judge_user)
      end

      after do
        DatabaseRequestCounter.disable
      end

      it "should return JudgeLegacyTasks" do
        get :for_appeal, params: { appeal_id: legacy_appeal.vacols_id, role: "judge" }

        assert_response :success
        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 4
        task = response_body["tasks"][0]
        expect(task["id"]).to eq(legacy_appeal.vacols_id)
        expect(task["attributes"]["type"]).to eq(JudgeLegacyDecisionReviewTask.name)
        expect(task["attributes"]["user_id"]).to eq(judge_user.css_id)
        expect(task["attributes"]["appeal_id"]).to eq(legacy_appeal.id)
        expect(task["attributes"]["available_actions"].size).to eq 2

        expect(DatabaseRequestCounter.get_counter(:vacols)).to eq(18)
      end

      context "when appeal is not assigned to current user" do
        let(:another_judge) { create(:user) }
        let!(:judge_staff2) { create(:staff, :judge_role, sdomainid: another_judge.css_id) }
        let(:legacy_appeal2) do
          create(:legacy_appeal,
                 vacols_case:
                 create(:case, :assigned, bfcorlid: "0000000000S", user: another_judge))
        end

        it "should not return available actions" do
          get :for_appeal, params: { appeal_id: legacy_appeal2.vacols_id, role: "judge" }

          assert_response :success
          response_body = JSON.parse(response.body)
          expect(response_body["tasks"].length).to eq 2
          task = response_body["tasks"][0]
          expect(task["id"]).to eq(legacy_appeal2.vacols_id)
          expect(task["attributes"]["type"]).to eq(JudgeLegacyDecisionReviewTask.name)
          expect(task["attributes"]["user_id"]).to eq(another_judge.css_id)
          expect(task["attributes"]["appeal_id"]).to eq(legacy_appeal2.id)
          expect(task["attributes"]["available_actions"].size).to eq 0
        end
      end
    end

    context "when user is an attorney" do
      before { User.authenticate!(user: attorney_user) }

      it "should return AttorneyLegacyTasks" do
        get :for_appeal, params: { appeal_id: legacy_appeal.vacols_id, role: "attorney" }

        assert_response :success
        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 4
        task = response_body["tasks"][0]
        expect(task["id"]).to eq(legacy_appeal.vacols_id)
        expect(task["attributes"]["type"]).to eq("AttorneyLegacyTask")
        expect(task["attributes"]["user_id"]).to eq(attorney_user.css_id)
        expect(task["attributes"]["appeal_id"]).to eq(legacy_appeal.id)
        expect(task["attributes"]["available_actions"].size).to eq 3
      end

      context "when appeal is not assigned to current user" do
        let(:another_attorney) { create(:user) }
        let!(:attorney_staff2) { create(:staff, :attorney_role, sdomainid: another_attorney.css_id) }
        let(:legacy_appeal) do
          create(:legacy_appeal, vacols_case: create(:case, :assigned, bfcorlid: "0000000000S", user: another_attorney))
        end

        it "should not return available actions" do
          get :for_appeal, params: { appeal_id: legacy_appeal.vacols_id, role: "attorney" }

          assert_response :success
          response_body = JSON.parse(response.body)
          expect(response_body["tasks"].length).to eq 4
          task = response_body["tasks"][0]
          expect(task["id"]).to eq(legacy_appeal.vacols_id)
          expect(task["attributes"]["type"]).to eq("AttorneyLegacyTask")
          expect(task["attributes"]["user_id"]).to eq(another_attorney.css_id)
          expect(task["attributes"]["appeal_id"]).to eq(legacy_appeal.id)
          expect(task["attributes"]["available_actions"].size).to eq 0
        end
      end
    end

    context "when user is a colocated staffer" do
      before { User.authenticate!(user: colocated_user) }

      it "should return ColocatedTasks" do
        get :for_appeal, params: { appeal_id: appeal.uuid, role: "colocated" }

        assert_response :success
        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 2

        colocated_task = response_body["tasks"].find { |task| task["attributes"]["type"] == "IhpColocatedTask" }
        expect(colocated_task).to_not be_nil
        expect(colocated_task["attributes"]["assigned_to"]["css_id"]).to eq colocated_user.css_id
        expect(colocated_task["attributes"]["appeal_id"]).to eq appeal.id
      end
    end

    context "when user is VSO" do
      let(:vso_user) { create(:user, roles: ["VSO"]) }
      let!(:vso_task) do
        create(:ama_colocated_task, :ihp, appeal: appeal, assigned_to: vso_user, assigned_by: assigning_user)
      end
      before { User.authenticate!(user: vso_user) }

      it "should only return VSO tasks" do
        get :for_appeal, params: { appeal_id: appeal.uuid }

        response_body = JSON.parse(response.body)
        expect(response_body["tasks"].length).to eq 1

        task = response_body["tasks"][0]
        expect(task["attributes"]["type"]).to eq "IhpColocatedTask"
        expect(task["attributes"]["assigned_to"]["css_id"]).to eq vso_user.css_id
        expect(task["attributes"]["appeal_id"]).to eq appeal.id

        expect(appeal.tasks.size).to eq 3
      end
    end
  end

  describe "GET cases_to_schedule/:ro" do
    context "when veteran is defined with regional office and hearing location" do
      let!(:vacols_case) do
        create(
          :case,
          bfcorlid: "#{veteran.file_number}S",
          folder: create(:folder, tinum: "docket-number"),
          bfregoff: "RO04",
          bfcurloc: "57",
          bfhr: "2",
          bfdocind: HearingDay::REQUEST_TYPES[:video]
        )
      end
      let(:closest_regional_office) { "RO10" }
      let(:address) { "Fake Address" }
      let!(:veteran) { create(:veteran) }

      it "gets veterans ready for hearing schedule" do
        BGSService.instance_methods(false).each do |method_name|
          expect_any_instance_of(BGSService).not_to receive(method_name)
        end

        AppealRepository.create_schedule_hearing_tasks.each do |appeal|
          appeal.update(closest_regional_office: closest_regional_office)

          AvailableHearingLocations.create(
            appeal: appeal,
            address: address,
            distance: 0,
            facility_type: "va_health_facility"
          )
        end

        get :ready_for_hearing_schedule, params: { ro: closest_regional_office }
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)["data"]

        expect(data.size).to be(1)
        expect(data.first["attributes"]["closest_regional_office"]["location_hash"]["city"]).to eq(
          RegionalOffice.find!(closest_regional_office).city
        )
        expect(data.first["attributes"]["available_hearing_locations"].first["address"]).to eq(
          address
        )
      end
    end
  end

  describe "POST tasks/:id/reschedule" do
    context "when the task is not a NoShowHearingTask" do
      let(:task) { create(:task) }
      it "returns an error" do
        post(:reschedule, params: { id: task.id })
        response_body = JSON.parse(response.body)
        expect(response.status).to eq(403)
        expect(response_body["errors"].length).to eq(1)
        expect(response_body["errors"].first["title"]).to eq(COPY::NO_SHOW_HEARING_TASK_RESCHEDULE_FORBIDDEN_ERROR)
      end
    end

    context "when the task is a NoShowHearingTask" do
      let(:root_task) { create(:root_task) }
      let(:parent_hearing_task) { create(:hearing_task, parent: root_task) }
      let(:task) { create(:no_show_hearing_task, parent: parent_hearing_task) }
      it "creates the new ScheduleHearingTask as expected" do
        post(:reschedule, params: { id: task.id })
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST tasks/:id/request_hearing_disposition_change" do
    let!(:hearing_mgmt_user) do
      create(:user, full_name: "Janaan Handal", station_id: 101, roles: ["Build HearSched"])
    end
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let(:params) { nil }
    let(:instructions) { "these are my detailed instructions." }

    before do
      HearingsManagement.singleton.add_user(hearing_mgmt_user)
      User.authenticate!(user: hearing_mgmt_user)
    end

    subject { post(:request_hearing_disposition_change, params: params) }

    context "when the task is a no show hearing task with a HearingTask ancestor" do
      let(:hearing_task) { create(:hearing_task, parent: root_task, appeal: appeal) }
      let(:disposition_task) do
        create(:assign_hearing_disposition_task, parent: hearing_task, appeal: appeal)
      end
      let!(:task) { create(:no_show_hearing_task, parent: disposition_task, appeal: appeal) }
      let(:params) do
        {
          id: task.id,
          tasks: [
            {
              type: ChangeHearingDispositionTask.name,
              external_id: appeal.external_id,
              parent_id: task.id,
              instructions: instructions
            }
          ]
        }
      end

      it "calls create_change_hearing_disposition_task on the NoShowHearingTask" do
        expect_any_instance_of(NoShowHearingTask)
          .to receive(:create_change_hearing_disposition_task)
          .with(instructions)

        subject
      end
    end

    context "when the task is a schedule hearing task with a past hearing with a disposition" do
      let(:hearing_day) { create(:hearing_day) }
      let(:past_hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
      let(:hearing) do
        create(:hearing, appeal: appeal, hearing_day: hearing_day, disposition: past_hearing_disposition)
      end
      let(:hearing_task) do
        create(:hearing_task, :completed, parent: root_task, appeal: appeal)
      end
      let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
      let!(:hearing_task_2) { create(:hearing_task, parent: root_task, appeal: appeal) }
      let!(:association_2) do
        create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
      end
      let!(:task) { create(:schedule_hearing_task, parent: hearing_task_2, appeal: appeal) }
      let(:params) do
        {
          id: task.id,
          tasks: [
            {
              type: ScheduleHearingTask.name,
              external_id: appeal.external_id,
              parent_id: task.id,
              instructions: instructions
            }
          ]
        }
      end

      it "calls create_change_hearing_disposition_task on the ScheduleHearingTask" do
        expect_any_instance_of(ScheduleHearingTask)
          .to receive(:create_change_hearing_disposition_task)
          .with(instructions)

        subject
      end

      context "the past hearing has no disposition" do
        let(:past_hearing_disposition) { nil }

        it "returns an error" do
          subject

          response_body = JSON.parse(response.body)
          expect(response.status).to eq(403)
          expect(response_body["errors"].length).to eq(1)
          expect(response_body["errors"].first["title"]).to eq(COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR)
        end
      end
    end

    context "when the task doesn't have a HearingTask ancestor" do
      let!(:task) do
        create(:track_veteran_task, parent: root_task, appeal: appeal)
      end
      let(:params) do
        {
          id: task.id,
          tasks: [
            {
              type: ChangeHearingDispositionTask.name,
              external_id: appeal.external_id,
              parent_id: task.id,
              instructions: instructions
            }
          ]
        }
      end

      it "returns an error" do
        subject

        response_body = JSON.parse(response.body)
        expect(response.status).to eq(403)
        expect(response_body["errors"].length).to eq(1)
        expect(response_body["errors"].first["title"]).to eq(COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR)
      end
    end
  end
end
