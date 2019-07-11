# frozen_string_literal: true

require "rails_helper"

RSpec.describe LegacyTasksController, type: :controller do
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
      let(:caseflow_only_user) { FactoryBot.create(:user) }

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

  describe "POST /legacy_tasks" do
    let(:attorney) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }
    let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    before do
      User.stub = user
      @staff_user = FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
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
        @appeal = FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case, staff: @staff_user))
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
            "appeal_id": create(:legacy_appeal, vacols_case: FactoryBot.create(:case)).id,
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
    let(:attorney) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }
    before do
      User.stub = user
      @staff_user = FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
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
        @appeal = FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case, staff: @staff_user))
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
          FactoryBot.create(:decass, defolder: @appeal.vacols_id, deadtim: today)
          FactoryBot.create(:decass, defolder: @appeal.vacols_id, deadtim: yesterday)
          task_id = "#{@appeal.vacols_id}-2018-04-18"

          patch :update, params: { tasks: params, id: task_id }

          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body["task"]["data"]["attributes"]["task_id"]).to eq task_id
        end
      end
    end
  end
end
