# frozen_string_literal: true

RSpec.describe LegacyTasksController, :all_dbs, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
  end

  describe "GET legacy_tasks/xxx" do
    let(:user) { create(:user) }
    before do
      create(:staff, role, sdomainid: user.css_id)
      User.authenticate!(user: user)
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

    context "user is a dispatch user" do
      let(:role) { :dispatch_role }

      it "should not process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 400
      end
    end

    context "user does not have a role" do
      let(:role) { nil }
      let(:caseflow_only_user) { create(:user) }

      it "should return an invalid role error" do
        get :index, params: { user_id: caseflow_only_user.id }
        expect(response.status).to eq(400)
      end

      it "should return a valid response when we explicitly pass the role as a parameter" do
        get :index, params: { user_id: caseflow_only_user.id, role: "attorney" }
        expect(response.status).to eq(200)
      end
    end
  end

  context "GET :user_id/assign" do
    let(:user) { create(:user) }
    before do
      create(:staff, sdomainid: user.css_id)
      User.authenticate!(user: user)
    end

    context "CSS_ID in URL is valid" do
      it "returns 200" do
        [user.id, user.css_id].each do |user_id_path|
          get :index, params: { user_id: user_id_path }
          expect(response.status).to eq 200
        end
      end
    end
    context "css_id in URL is invalid" do
      it "returns 400" do
        [-1, "BAD_CSS_ID"].each do |user_id_path|
          get :index, params: { user_id: user_id_path }
          expect(response.status).to eq 400
        end
      end
    end
  end

  describe "POST /legacy_tasks" do
    let(:attorney) { create(:user) }
    let(:user) { create(:user) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    before do
      User.stub = user
      @staff_user = create(:staff, role, sdomainid: user.css_id)
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    context "when current user is an attorney" do
      let(:role) { :attorney_role }
      let(:params) do
        {
          "appeal_id": appeal.id,
          "assigned_to_id": user.id
        }
      end

      it "fails because user is not a judge" do
        post :create, params: { tasks: params }
        expect(response.status).to eq(400)
      end
    end

    context "when current user is a judge" do
      let(:role) { :judge_role }
      let(:params) do
        {
          "appeal_id": appeal.id,
          "assigned_to_id": attorney.id
        }
      end
      before do
        @appeal = create(:legacy_appeal, vacols_case: create(:case, staff: @staff_user))
      end

      it "should be successful" do
        params = {
          "appeal_id": @appeal.id,
          "assigned_to_id": attorney.id
        }
        allow(QueueRepository).to receive(:assign_case_to_attorney!).with(
          judge: user,
          attorney: attorney,
          vacols_id: @appeal.vacols_id
        ).and_return(true)

        post :create, params: { tasks: params }
        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["task"]["data"]["attributes"]["appeal_id"]).to eq @appeal.id
      end

      context "when judge does not have access to the appeal" do
        it "should not be successful" do
          params = {
            "appeal_id": create(:legacy_appeal, vacols_case: create(:case)).id,
            "assigned_to_id": attorney.id
          }

          post :create, params: { tasks: params }
          expect(response.status).to eq 400
          body = JSON.parse(response.body)
          expect(body["errors"].first["detail"]).to match(/Case already assigned/)
        end
      end

      context "when appeal is not found" do
        let(:params) do
          {
            "appeal_id": 4_646_464,
            "assigned_to_id": attorney.id
          }
        end

        it "should not be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 404
        end
      end

      context "when case is already assigned" do
        before do
          allow(Raven).to receive(:capture_exception)
        end

        it "should be not successful" do
          params = {
            "appeal_id": @appeal.id,
            "assigned_to_id": attorney.id
          }
          error_msg = "Case is already assigned"
          allow(QueueRepository).to receive(:assign_case_to_attorney!).and_raise(
            Caseflow::Error::LegacyCaseAlreadyAssignedError.new(message: error_msg)
          )
          post :create, params: { tasks: params }
          expect(response.status).to eq 400
          expect(Raven).to_not receive(:capture_exception)
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["detail"]).to eq error_msg
        end
      end

      context "when attorney is not found" do
        let(:params) do
          {
            "appeal_id": @appeal.id,
            "assigned_to_id": 7_777_777_777
          }
        end

        it "should not be successful" do
          allow(UserRepository).to receive(:user_info_from_vacols).and_return(roles: ["judge"])
          post :create, params: { tasks: params }
          expect(response.status).to eq 400
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["detail"]).to eq "Assigned to can't be blank"
        end
      end
    end
  end

  describe "PATCH legacy_tasks/:id" do
    let(:attorney) { create(:user) }
    let(:user) { create(:user) }
    before do
      User.stub = user
      @staff_user = create(:staff, role, sdomainid: user.css_id)
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    context "when current user is an attorney" do
      let(:role) { :attorney_role }
      let(:params) do
        {
          "assigned_to_id": user.id
        }
      end

      it "fails because the current user is not a judge" do
        patch :update, params: { tasks: params, id: "3615398-2018-04-18" }
        expect(response.status).to eq(400)
      end
    end

    context "when current user is a judge" do
      let(:role) { :judge_role }
      let(:params) do
        {
          "assigned_to_id": attorney.id
        }
      end
      before do
        @appeal = create(:legacy_appeal, vacols_case: create(:case, staff: @staff_user))
      end

      it "should be successful" do
        allow(QueueRepository).to receive(:reassign_case_to_attorney!).with(
          judge: user,
          attorney: attorney,
          vacols_id: @appeal.vacols_id,
          created_in_vacols_date: "2018-04-18".to_date
        ).and_return(true)

        patch :update, params: { tasks: params, id: "#{@appeal.vacols_id}-2018-04-18" }
        expect(response.status).to eq 200
      end

      context "when attorney is not found" do
        let(:params) do
          {
            "assigned_to_id": 7_777_777_777
          }
        end

        it "should not be successful" do
          patch :update, params: { tasks: params, id: "#{@appeal.vacols_id}-2018-04-18" }
          expect(response.status).to eq 400
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["detail"]).to eq "Assigned to can't be blank"
        end
      end

      context "when there is more than one decass record for the appeal" do
        it "should return the one created last" do
          allow(QueueRepository).to receive(:reassign_case_to_attorney!).with(
            judge: user,
            attorney: attorney,
            vacols_id: @appeal.vacols_id,
            created_in_vacols_date: "2018-04-18".to_date
          ).and_return(true)
          today = Time.utc(2018, 4, 18)
          yesterday = Time.utc(2018, 4, 17)
          create(:decass, defolder: @appeal.vacols_id, deadtim: today)
          create(:decass, defolder: @appeal.vacols_id, deadtim: yesterday)
          task_id = "#{@appeal.vacols_id}-2018-04-18"

          patch :update, params: { tasks: params, id: task_id }

          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body["task"]["data"]["attributes"]["task_id"]).to eq task_id
        end
      end
    end
  end

  describe "Das Deprecation" do
    before do
      FeatureToggle.enable!(:legacy_das_deprecation)
      User.authenticate!(user: judge)
    end

    after { FeatureToggle.disable!(:legacy_das_deprecation) }
    let(:task_type) { :attorney_task }
    let!(:vacols_case) { create(:case) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    let(:judge) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

    let(:attorney1) { create(:user) }
    let!(:vacols_attorney1) { create(:staff, :attorney_role, user: attorney1) }

    let(:attorney2) { create(:user) }
    let!(:vacols_attorney2) { create(:staff, :attorney_role, user: attorney2) }

    let(:root_task) { create(:root_task, appeal: appeal) }
    let!(:judge_assign_task) { JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge) }

    subject { post :create, params: { tasks: params } }

    let(:params) do
      {
        "appeal_id": appeal.id,
        "assigned_to_id": attorney1.id,
        "assigned_by_id": judge.id,
        "user_id": judge.id
      }
    end
    describe "AttorneyTask" do
      it "is created succesfully" do
        subject

        expect(response.status).to eq 200

        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.first["attributes"]["type"]).to eq AttorneyTask.name
        expect(response_body.first["attributes"]["appeal_id"]).to eq appeal.id
        expect(response_body.first["attributes"]["docket_number"]).to eq appeal.docket_number
        expect(response_body.first["attributes"]["appeal_type"]).to eq LegacyAppeal.name

        attorney_task = AttorneyTask.find_by(appeal: appeal)
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
        expect(attorney_task.assigned_to).to eq attorney1

        judge_assign_task = JudgeAssignTask.find_by(appeal: appeal)
        expect(judge_assign_task.status).to eq Constants.TASK_STATUSES.completed
      end

      it "reassigns succesfully" do
        subject

        response_body = JSON.parse(response.body)["tasks"]["data"]

        patch :update, params: {
          tasks: {
            "appeal_id": appeal.id,
            "assigned_to_id": attorney2.id,
            "assigned_by_id": judge
          },
          id: response_body.first["id"]
        }

        expect(response.status).to eq 200

        response_body = JSON.parse(response.body)["task"]["data"]
        expect(response_body["attributes"]["assigned_to"]["id"]).to eq attorney2.id
      end
    end
  end

  describe "POST legacy_tasks/assign_to_judge" do
    let(:assigning_judge) { create(:user) }
    let(:assignee_judge) { create(:user) }
    let(:assigning_judge_staff) { create(:staff, :judge_role, sdomainid: assigning_judge.css_id) }
    let!(:assignee_judge_staff) { create(:staff, :judge_role, sdomainid: assignee_judge.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, staff: assigning_judge_staff)) }
    let(:params) { { "appeal_id": appeal.id, "assigned_to_id": assignee_judge.id } }

    before do
      User.stub = assigning_judge
    end

    it "should be successful" do
      allow(QueueRepository).to receive(:update_location_to_judge).with(
        appeal.vacols_id,
        assignee_judge
      ).and_return(true)

      patch :assign_to_judge, params: { tasks: params }
      expect(response.status).to eq 200
    end
  end
end
