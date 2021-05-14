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
        response_body = JSON.parse(response.body)["queue_config"]["tabs"]

        # Includes both assigned and in progress tasks
        assigned_tasks = response_body[0]["tasks"]
        expect(assigned_tasks.size).to eq 2
        expect(assigned_tasks.map { |task| task["id"] }).to match_array([task11, task12].map(&:id).map(&:to_s))

        # Includes both on hold tasks and legacy colocated tasks
        on_hold_tasks = response_body[1]["tasks"]
        expect(on_hold_tasks.size).to eq 3
        expect(on_hold_tasks.map { |task| task["id"] }).to match_array([task1, task2, task14].map(&:id).map(&:to_s))

        # Only includes recently completed tasks
        completed_tasks = response_body[2]["tasks"]
        expect(completed_tasks.size).to eq 1
        expect(completed_tasks.map { |task| task["id"] }).to match_array([task13].map(&:id).map(&:to_s))
      end
    end

    context "when user is an attorney and has no tasks" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["queue_config"]["tabs"]
        expect(response_body.all? { |tab| tab["tasks"].count.eql?(0) }).to be true
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

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "colocated" }
        response_body = JSON.parse(response.body)["queue_config"]["tabs"]

        assigned = response_body[0]["tasks"].find { |task| task["id"] == task4.id.to_s }
        expect(assigned["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil
        expect(assigned["attributes"]["aod"]).to be true

        in_progress = response_body[0]["tasks"].find { |task| task["id"] == task5.id.to_s }
        expect(in_progress["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        ama = response_body[0]["tasks"].find { |task| task["id"] == task_ama_colocated_aod.id.to_s }
        expect(ama["attributes"]["aod"]).to be true

        recently_completed_task = response_body[2]["tasks"].find { |task| task["id"] == task6.id.to_s }
        expect(recently_completed_task["attributes"]["status"]).to eq Constants.TASK_STATUSES.completed
      end
    end

    context "when getting review tasks for a judge" do
      let(:role) { :judge_role }
      let(:attorney) { create(:user) }
      let!(:judge_team) { JudgeTeam.create_for_judge(user).tap { |team| team.add_user(attorney) } }

      let!(:task8) { create(:ama_judge_decision_review_task, assigned_to: user, assigned_by: user) }
      let!(:task9) { create(:ama_judge_decision_review_task, :in_progress, assigned_to: user, assigned_by: user) }
      let!(:task16) { create(:ama_judge_decision_review_task, :on_hold, assigned_to: user, assigned_by: user) }
      let!(:task10) { create(:ama_judge_decision_review_task, :completed, assigned_to: user, assigned_by: user) }
      let!(:task15) do
        create(:ama_judge_decision_review_task, :completed_in_the_past, assigned_to: user, assigned_by: user)
      end
      let!(:task17) { create(:ama_attorney_task, assigned_to: attorney, assigned_by: user) }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "judge" }
        response_body = JSON.parse(response.body)["queue_config"]["tabs"]
        expect(response_body.size).to eq 1
        response_body = response_body[0]["tasks"]

        assigned = response_body.find { |task| task["id"] == task8.id.to_s }
        expect(assigned["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil

        in_progress = response_body.find { |task| task["id"] == task9.id.to_s }
        expect(in_progress["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        # Ensure we don't include recently completed tasks, on hold tasks, or attorney tasks
        expect(response_body.count { |task| task["id"] == task10.id.to_s }).to eq 0
        expect(response_body.count { |task| task["id"] == task16.id.to_s }).to eq 0
        expect(response_body.count { |task| task["id"] == task17.id.to_s }).to eq 0
      end
    end

    context "when getting tasks assign for a judge" do
      let(:role) { :judge_role }
      let(:attorney) { create(:user) }
      let!(:judge_team) { JudgeTeam.create_for_judge(user).tap { |team| team.add_user(attorney) } }

      let!(:task8) { create(:ama_judge_assign_task, assigned_to: user, assigned_by: user) }
      let!(:task9) { create(:ama_judge_assign_task, :in_progress, assigned_to: user, assigned_by: user) }
      let!(:task16) { create(:ama_judge_assign_task, :on_hold, assigned_to: user, assigned_by: user) }
      let!(:task10) { create(:ama_judge_assign_task, :completed, assigned_to: user, assigned_by: user) }
      let!(:task15) do
        create(:ama_judge_assign_task, :completed_in_the_past, assigned_to: user, assigned_by: user)
      end
      let!(:task17) { create(:ama_attorney_task, assigned_to: attorney, assigned_by: user) }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id, role: "judge", type: "assign" }
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2

        assigned = response_body.find { |task| task["id"] == task8.id.to_s }
        expect(assigned["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
        expect(assigned["attributes"]["placed_on_hold_at"]).to be nil

        in_progress = response_body.find { |task| task["id"] == task9.id.to_s }
        expect(in_progress["attributes"]["status"]).to eq Constants.TASK_STATUSES.in_progress
        expect(in_progress["attributes"]["placed_on_hold_at"]).to be nil

        # Ensure we don't include recently completed tasks, on hold tasks, or attorney tasks
        expect(response_body.count { |task| task["id"] == task10.id.to_s }).to eq 0
        expect(response_body.count { |task| task["id"] == task16.id.to_s }).to eq 0
        expect(response_body.count { |task| task["id"] == task17.id.to_s }).to eq 0
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

        it "returns tasks" do
          get :index, params: { user_id: user.id, role: "unknown" }
          expect(response).to be_successful

          data = JSON.parse(response.body)["queue_config"]["tabs"][0]["tasks"]

          expect(data.size).to be(1)
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

      context "when current user is a judge" do
        let(:role) { :judge_role }
        let(:parent) { create(:ama_judge_decision_review_task, assigned_to: user) }

        context "when multiple admin actions with task type field" do
          let(:params) do
            [{
              "external_id": appeal.vacols_id,
              "parent_id": parent.id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": "do this"
            }, {
              "external_id": appeal.vacols_id,
              "parent_id": parent.id,
              "type": MissingRecordsColocatedTask.name,
              "instructions": "another one"
            }]
          end

          it "should be successful" do
            expect(AppealRepository).to receive(:update_location!).exactly(2).times

            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.size).to eq(5)

            # Ensure the parent task is also returned
            expect(response_body.first["attributes"]["label"]).to eq "Review"
            expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
            expect(response_body.first["id"]).to eq parent.id.to_s

            # Ensure there is a colocated org parent task for the AddressVerificationColocatedTask
            expect(response_body.second["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
            expect(response_body.second["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.second["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.second["attributes"]["label"]).to eq "Address verification"

            # Ensure there is a AddressVerificationColocatedTask user task created
            expect(response_body.third["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.third["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.third["attributes"]["instructions"][0]).to eq "do this"
            expect(response_body.third["attributes"]["label"]).to eq "Address verification"

            # Ensure there is a MissingRecordsColocatedTask user task created
            expect(response_body.last["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
            expect(response_body.last["attributes"]["appeal_id"]).to eq appeal.id
            expect(response_body.last["attributes"]["instructions"][0]).to eq "another one"
            expect(response_body.last["attributes"]["label"]).to eq "Missing records"

            # Assignee should be the same person for the two user tasks
            id = response_body.third["attributes"]["assigned_to"]["id"]
            expect(response_body.last["attributes"]["assigned_to"]["id"]).to eq id
          end
        end

        context "when there are no instructions" do
          let(:params) do
            [{
              "external_id": appeal.vacols_id,
              "parent_id": parent.id,
              "type": AddressVerificationColocatedTask.name
            }]
          end

          it "should not populate instructions" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            task = response_body.last

            expect(task["attributes"]["instructions"]).to match_array []
          end
        end

        context "when instructions are a string" do
          let(:params) do
            [{
              "external_id": appeal.vacols_id,
              "parent_id": parent.id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": "instructions"
            }]
          end

          it "should populate instructions" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            task = response_body.last

            expect(task["attributes"]["instructions"]).to match_array ["instructions"]
          end
        end

        context "when instructions are an array" do
          let(:params) do
            [{
              "external_id": appeal.vacols_id,
              "parent_id": parent.id,
              "type": AddressVerificationColocatedTask.name,
              "instructions": ["instructions", "instructions 2"]
            }]
          end

          it "should populate instructions" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            task = response_body.last

            expect(task["attributes"]["instructions"]).to match_array ["instructions", "instructions 2"]
          end
        end
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

      context "when an AddressChangeMailTask is created for an inactive appeal" do
        let(:root_task) { create(:root_task) }

        let(:params) do
          [{
            "external_id": root_task.appeal.external_id,
            "type": AddressChangeMailTask.name,
            "parent_id": root_task.id
          }]
        end

        before do
          allow(AddressChangeMailTask).to receive(:case_active?).and_return(false)
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
      patch :update, params: { task: { status: Constants.TASK_STATUSES.completed }, id: admin_action.id }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["tasks"]["data"]
      expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.completed
      expect(response_body.first["attributes"]["closed_at"]).to_not be nil
      expect(admin_action.reload.versions.length).to eq 1
      versions = PaperTrail::Version.where(request_id: admin_action.versions.first.request_id)
      expect(versions.length).to eq 1
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

    context "when payload includes virtual hearing attributes and complete status" do
      let(:hearing_day) do
        create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video], regional_office: "RO31")
      end
      let(:appellant_email) { "fake@email.com" }
      let(:virtual_hearing_attributes) do
        {
          appellant_email: appellant_email
        }
      end

      let(:hearing_values) do
        {
          scheduled_time_string: "08:30",
          hearing_day_id: hearing_day.id,
          hearing_location: {
            name: "St. Louis Regional Benefit Office",
            address: "9700 Page Ave.",
            city: "ST. Louis",
            state: "MO",
            zip_code: "63132",
            distance: 0,
            classification: "Regional Benefit Office",
            facility_id: "vba_331",
            facility_type: "va_benefits_facility"
          }
        }
      end

      subject { patch :update, as: :json, params: params }

      shared_examples "returns alerts" do
        it "returns alerts", :aggregate_failures do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]
          expect(response_body["alerts"]).not_to eq(nil)
        end
      end

      shared_examples_for "request with invalid attributes" do
        let(:virtual_hearing_attributes) do
          {
            appellant_email: "blah"
          }
        end
        it "fails to schedule hearing", :aggregate_failures do
          subject

          expect(response.status).not_to eq 200
        end
      end

      context "when task is ScheduleHearingTask" do
        let(:params) do
          {
            task: {
              status: Constants.TASK_STATUSES.completed,
              business_payloads: {
                values: {
                  **hearing_values,
                  virtual_hearing_attributes: virtual_hearing_attributes
                }
              }
            },
            id: admin_action.id
          }
        end

        let(:task_type) { :schedule_hearing_task }

        it "creates a virtual hearing with correct attributes", :aggregate_failures do
          subject

          expect(response.status).to eq 200

          # get the new hearing
          response_body = JSON.parse(response.body)["tasks"]["data"]
          external_hearing_id = response_body[0]["attributes"]["external_hearing_id"]
          new_hearing = Hearing.find_by(uuid: external_hearing_id)

          expect(new_hearing.virtual?).to eq(true)
          expect(new_hearing.virtual_hearing).not_to eq(nil)
          expect(new_hearing.virtual_hearing.appellant_email).to eq(appellant_email)
        end

        include_examples "returns alerts"

        it_behaves_like "request with invalid attributes"
      end

      context "when task is AssignHearingDispositionTask" do
        let(:task_type) { :assign_hearing_disposition_task }
        let(:admin_action) do
          create(task_type, parent: hearing_task, assigned_by: assigned_by_user, assigned_to: assigned_to_user)
        end
        let(:hearing_task) { create(:hearing_task, parent: root_task) }
        let(:prev_hearing) { create(:hearing, hearing_day: hearing_day) }
        let!(:hearing_task_association) do
          HearingTaskAssociation.create!(hearing: prev_hearing, hearing_task: hearing_task)
        end
        let(:params) do
          {
            task: {
              status: Constants.TASK_STATUSES.cancelled,
              business_payloads: {
                values: {
                  after_disposition_update: {
                    new_hearing_attrs: {
                      **hearing_values,
                      virtual_hearing_attributes: virtual_hearing_attributes
                    },
                    action: "reschedule"
                  },
                  disposition: Constants.HEARING_DISPOSITION_TYPES.postponed
                }
              }
            },
            id: admin_action.id
          }
        end

        it "creates a virtual hearing with correct attributes", :aggregate_failures do
          subject

          expect(response.status).to eq 200

          response_body = JSON.parse(response.body)["tasks"]["data"]

          # get the new hearing
          appeal_id = response_body[0]["attributes"]["appeal_id"]
          new_hearing_task = HearingTask.find_by(appeal_id: appeal_id, status: Constants.TASK_STATUSES.on_hold)
          new_hearing = new_hearing_task.hearing

          expect(new_hearing.virtual?).to eq(true)
          expect(new_hearing.virtual_hearing).not_to eq(nil)
          expect(new_hearing.virtual_hearing.appellant_email).to eq(appellant_email)
        end

        include_examples "returns alerts"

        it_behaves_like "request with invalid attributes"

        # See https://github.com/department-of-veterans-affairs/caseflow/issues/15430
        context "when virtual hearing payload includes virtual hearing status" do
          let(:virtual_hearing_attributes) do
            {
              appellant_email: "valid@caseflow.va.gov",
              status: "pending"
            }
          end

          it_behaves_like "request with invalid attributes"
        end
      end

      context "when task is ChangeHearingRequestTypeTask" do
        let(:attorney_user) { create(:user) }
        let(:vacols_case) do
          create(
            :case,
            :assigned,
            bfcorlid: "0000000000S",
            bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
            bfhr: VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value],
            bfdocind: nil
          )
        end
        let!(:legacy_appeal) do
          create(:legacy_appeal, vacols_case: vacols_case)
        end

        let(:task_type) { :change_hearing_request_type_task }
        let(:action) do
          create(task_type, appeal: legacy_appeal, assigned_by: assigned_by_user, assigned_to: assigned_to_user)
        end

        let(:params) do
          {
            task: {
              status: Constants.TASK_STATUSES.completed,
              business_payloads: {
                values: {
                  changed_hearing_request_type: HearingDay::REQUEST_TYPES[:video]
                }
              }
            },
            id: action.id
          }
        end

        it "sucessfully updates appeal and closes related tasks", :aggregate_failures do
          # Ensure that the changed request type is nil before we take action
          expect(legacy_appeal.changed_hearing_request_type).to eq(nil)
          subject

          # Ensure the update successfully completed the task and changed the appeal
          expect(response.status).to eq 200
          expect(legacy_appeal.reload.changed_hearing_request_type).to eq(HearingDay::REQUEST_TYPES[:video])
          expect(action.reload.status).to eq(Constants.TASK_STATUSES.completed)
          expect(ChangeHearingRequestTypeTask.find_by(
            appeal: legacy_appeal
          ).status).to eq(Constants.TASK_STATUSES.completed)
          expect(ScheduleHearingTask.find_by(appeal: legacy_appeal).status).to eq(Constants.TASK_STATUSES.assigned)
          expect(CachedAppeal.count).to eq(1)
          expect(CachedAppeal.first.vacols_id).to eq(legacy_appeal.vacols_id)
          expect(CachedAppeal.first.former_travel).to eq(true)
          expect(CachedAppeal.first.hearing_request_type).to eq("Video")
          expect(CachedAppeal.first.closest_regional_office_key).to eq("RO17") # Default RO based on address geomatch
        end

        it "changes the vacols location to CASEFLOW" do
          expect { subject }
            .to change { vacols_case.reload.bfcurloc }
            .from(LegacyAppeal::LOCATION_CODES[:schedule_hearing])
            .to(LegacyAppeal::LOCATION_CODES[:caseflow])
        end
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

    shared_examples "judge view legacy tasks" do
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

        expect(DatabaseRequestCounter.get_counter(:vacols)).to eq(14)
      end
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

      it_behaves_like "judge view legacy tasks"

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

    context "when the user is a memeber of the special case movement team" do
      let(:legacy_appeal) do
        create(:legacy_appeal,
               vacols_case:
               create(:case, :assigned, bfcorlid: "0000000000S", user: judge_user))
      end

      before do
        scm_user = create(:user)
        SpecialCaseMovementTeam.singleton.add_user(scm_user)
        User.authenticate!(user: judge_user)
        DatabaseRequestCounter.enable
      end
      after { DatabaseRequestCounter.disable }

      it_behaves_like "judge view legacy tasks"
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
        expect(response_body["tasks"].length).to eq 3

        colocated_task = response_body["tasks"].find { |task| task["attributes"]["type"] == "IhpColocatedTask" }
        expect(colocated_task).to_not be_nil
        expect(colocated_task["attributes"]["timer_ends_at"]).to be_nil
        expect(colocated_task["attributes"]["assigned_to"]["css_id"]).to eq colocated_user.css_id
        expect(colocated_task["attributes"]["appeal_id"]).to eq appeal.id
        expect(colocated_task["attributes"]["status"]).to eq Task.statuses[:in_progress]
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

        expect(appeal.tasks.size).to eq 5
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
      let(:hearing_task) { create(:hearing_task, parent: root_task) }
      let(:disposition_task) do
        create(:assign_hearing_disposition_task, parent: hearing_task)
      end
      let!(:task) { create(:no_show_hearing_task, parent: disposition_task) }
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
          .with([instructions])

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
        create(:hearing_task, :completed, parent: root_task)
      end
      let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
      let!(:hearing_task_2) { create(:hearing_task, parent: root_task) }
      let!(:association_2) do
        create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
      end
      let!(:task) { create(:schedule_hearing_task, parent: hearing_task_2) }
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
          .with([instructions])

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
        create(:track_veteran_task, parent: root_task)
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
